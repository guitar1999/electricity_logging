#!/usr/bin/env python3

import argparse
import datetime
import os

try:
    import configparser
except ImportError:
    import ConfigParser as configparser

import psycopg2


def get_db_connection():
    config = configparser.RawConfigParser()
    config.read(os.path.join(os.environ.get('HOME'), '.pyconfig'))

    kwargs = {
        'host': config.get('pidb', 'DBHOST'),
        'database': config.get('pidb', 'DBNAME'),
        'user': config.get('pidb', 'DBUSER'),
    }

    if config.has_option('pidb', 'DBPORT'):
        kwargs['port'] = config.get('pidb', 'DBPORT')

    return psycopg2.connect(**kwargs)


def parse_args():
    parser = argparse.ArgumentParser(description='Backfill completed well-pump cycles into water_statistics.water_cycles.')
    parser.add_argument('--start-date', required=False, help='First date to backfill, YYYY-MM-DD.')
    parser.add_argument('--end-date', required=False, help='Last date to backfill, YYYY-MM-DD.')
    return parser.parse_args()


def parse_date(value):
    return datetime.datetime.strptime(value, '%Y-%m-%d').date()


def get_date_bounds(cursor, args):
    if args.start_date and args.end_date:
        return parse_date(args.start_date), parse_date(args.end_date)

    cursor.execute("""
        SELECT
            MIN(measurement_time)::DATE,
            MAX(measurement_time)::DATE
        FROM
            electricity_iotawatt.electricity_measurements
        WHERE
            watts_water_pump IS NOT NULL;
    """)
    min_date, max_date = cursor.fetchone()

    start_date = parse_date(args.start_date) if args.start_date else min_date
    end_date = parse_date(args.end_date) if args.end_date else max_date
    return start_date, end_date


def backfill_day(cursor, opdate):
    cursor.execute("""
        INSERT INTO water_statistics.water_cycles (cycle_start, cycle_end, sum_date, hour, runtime)
        SELECT
            wc.cycle_start,
            wc.cycle_end,
            wc.cycle_start::DATE AS sum_date,
            DATE_PART('HOUR', wc.cycle_start)::INTEGER AS hour,
            wc.runtime
        FROM
            water_completed_cycles(
                (%s::TIMESTAMP - '15 minutes'::INTERVAL),
                (%s::TIMESTAMP + '1 day 15 minutes'::INTERVAL)
            ) wc
        ON CONFLICT (cycle_start) DO
        UPDATE SET
            cycle_end = EXCLUDED.cycle_end,
            sum_date = EXCLUDED.sum_date,
            hour = EXCLUDED.hour,
            runtime = EXCLUDED.runtime;
    """, (opdate, opdate))
    return cursor.rowcount


def main():
    args = parse_args()
    db = get_db_connection()
    cursor = db.cursor()

    start_date, end_date = get_date_bounds(cursor, args)
    if start_date is None or end_date is None:
        print('No water pump measurements found.')
        cursor.close()
        db.close()
        return

    opdate = start_date
    while opdate <= end_date:
        rowcount = backfill_day(cursor, opdate)
        db.commit()
        print('Backfilled {0}: {1} cycle rows inserted/updated'.format(opdate, rowcount))
        opdate += datetime.timedelta(days=1)

    cursor.close()
    db.close()


if __name__ == '__main__':
    main()
