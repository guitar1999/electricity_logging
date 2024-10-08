#!/usr/bin/python

import argparse, ConfigParser, datetime, os, psycopg2, pytz


#####################
# Get the arguments #
#####################
parser = argparse.ArgumentParser(prog='generate_summary.py', description='Summarize Electricity Usage')
subparsers = parser.add_subparsers(help='Program Mode', dest='mode')
# Hourly
hour_parser = subparsers.add_parser('hour', help='Summarize Electricity by Hour')
hour_parser.add_argument('-d', '--date', dest='rundate', required=False, help='The day to run in format "YYYY-MM-DD".')
hour_parser.add_argument('-H', '--hour', dest='runhour', required=False, help='The hour to run.')
# Day
day_parser = subparsers.add_parser('day', help='Summarize Electricity by Day')
day_parser.add_argument('-d', '--date', dest='rundate', required=False, help='The day to run in format "YYYY-MM-DD".')
# Monthly
month_parser = subparsers.add_parser('month', help='Summarize Electricity by Month')
month_parser.add_argument('-m', '--month', dest='runmonth', required=False, help='The month to run (numeric).')
# Yearly
year_parser = subparsers.add_parser('year', help='Summarize Electricity by Year')
year_parser.add_argument('-y', '--year', dest='runyear', required=False, help='The year to run.')
# Parse the arguments
args = parser.parse_args()


##############
# Get config #
##############
config = ConfigParser.RawConfigParser()
config.read('{0}/.pyconfig'.format(os.environ.get('HOME')))
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')
dbport = config.get('pidb', 'DBPORT')
pickledir = config.get('pickledir', 'PICKLE_DIR')
tz = config.get('location', 'TZ')

###########################
# Connect to the database #
###########################
db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
cursor = db.cursor()


##############################
# Date and Time Calculations #
##############################
def fix_dow(dow):
    if dow == 7:
        return 0
    else:
        return dow

def hour_calc(now, rundate=None, runhour=None):
    if runhour:
        reset = False
        now = datetime.datetime.strptime(rundate, '%Y-%m-%d')
        if runhour != '23':
            hour = int(runhour) + 1
        else:
            hour = 0
            now = now + datetime.timedelta(1)
    else:
        reset = True
        hour = now.hour
    if hour == 0:
        ophour = 23
        opdate = now - datetime.timedelta(1)
    else:
        ophour = hour - 1
        opdate = now
    dow = fix_dow(opdate.isoweekday())
    starttime = datetime.datetime.combine(opdate.date(), datetime.time(ophour, 0, 0))
    endtime = datetime.datetime.combine(opdate.date(), datetime.time(ophour, 59, 59))
    return (hour, now, ophour, opdate, dow, starttime, endtime, reset)

def day_calc(now, rundate=None):
    if rundate:
        reset = False
        opdate = datetime.datetime.strptime(rundate, '%Y-%m-%d')
        now = opdate + datetime.timedelta(1)
    else:
        reset = True
        opdate = now - datetime.timedelta(1)
    starttime = datetime.datetime.combine(opdate.date(), datetime.time(0, 0, 0))
    endtime = datetime.datetime.combine(opdate.date(), datetime.time(23, 59, 59))
    dow = fix_dow(opdate.isoweekday())
    nowdow = fix_dow(now.isoweekday())
    return(opdate, now, dow, nowdow, starttime, endtime, reset)

def month_calc(now, runmonth=None):
    year = now.year
    if runmonth:
        reset = False
        opmonth = runmonth
        if opmonth == 12:
            month = 1
            year = year - 1
        else:
            month = opmonth + 1
    else:
        reset = True
        month = now.month
        opmonth = month - 1
        if opmonth == 0:
            opmonth = 12
        if opmonth == 12:
            year = year - 1
    starttime = datetime.datetime.combine(datetime.date(year, opmonth, 1), datetime.time(0, 0, 0))
    endtime = datetime.datetime.combine(datetime.date(year, opmonth, (datetime.date(year, month, 1) - datetime.timedelta(1)).day), datetime.time(23, 59, 59))
    return(opmonth, month, year, starttime, endtime, reset)

def year_calc(now, runyear=None):
    if runyear:
        reset = False
        opyear = runyear
    else:
        reset = True
        opyear = now.year - 1
    startime = datetime.datetime.combine(datetime.date(opyear, 1, 1), datetime.time(0, 0, 0))
    endtime = datetime.datetime.combine(datetime.date(opyear, 12, 31), datetime.time(23, 59, 59))
    return(opyear, startime, endtime, reset)


############
# Querying #
############

def reset_kwh():
    pass

def hour_query(now, opdate, hour, ophour, starttime, endtime, dow, reset):
    if reset:
        query = """UPDATE electricity.electricity_usage_hourly SET (kwh, complete, updated) = (0, 'no', '{0}:00:00') WHERE hour = {1};""".format(now.strftime('%Y-%m-%d %H'), hour)
        cursor.execute(query)
        db.commit()
    # Are the data complete
    query = """SELECT 't' = ANY(array_agg(tdiff * (watts_ch1 + watts_ch2) > 0)) FROM electricity.electricity_measurements WHERE measurement_time > '{0}' AND date_part('hour', measurement_time) = {1} AND tdiff >= 300 and tdiff * (watts_ch1 + watts_ch2) > 0;""".format(opdate.strftime('%Y-%m-%d'), ophour)
    cursor.execute(query)
    data = cursor.fetchall()
    maxint = data[0][0]
    if not maxint:
        complete = 'yes'
    else:
        complete = 'no'
    # KWH
    query = """UPDATE electricity.electricity_usage_hourly SET kwh = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity.electricity_measurements WHERE measurement_time > '{0}' AND measurement_time <= '{1}' AND date_part('hour', measurement_time) = {2}), complete = '{3}', updated = CURRENT_TIMESTAMP WHERE hour = {2} RETURNING kwh;""".format(starttime, endtime, ophour, complete)
    cursor.execute(query)
    db.commit()
    kwh = cursor.fetchall()[0][0]
    if not kwh:
        kwh = 0
    # Averages
    query = """WITH old AS (SELECT count, kwh_avg, updated FROM electricity_statistics.electricity_statistics_hourly WHERE hour = {0}), new AS (SELECT COUNT(DISTINCT measurement_time::DATE), COALESCE(SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.), 0) AS kwh FROM electricity.electricity_measurements e, old WHERE measurement_time > old.updated AND measurement_time <= '{1}' AND DATE_PART('hour', measurement_time) = {0}) UPDATE electricity_statistics.electricity_statistics_hourly SET (kwh_avg, count, updated) = (((old.kwh_avg * old.count + new.kwh) / (old.count + new.count)), old.count + new.count, CURRENT_TIMESTAMP) FROM old, new WHERE hour = {0};""".format(ophour, endtime)
    cursor.execute(query)
    query = """WITH old AS (SELECT count, kwh_avg, updated FROM electricity_statistics.electricity_statistics_hourly_dow WHERE hour = {0} AND dow = {2}), new AS (SELECT COUNT(DISTINCT measurement_time::DATE), COALESCE(SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.), 0) AS kwh FROM electricity.electricity_measurements e, old WHERE measurement_time > old.updated AND measurement_time <= '{1}' AND DATE_PART('hour', measurement_time) = {0} AND DATE_PART('dow', measurement_time) = {2}) UPDATE electricity_statistics.electricity_statistics_hourly_dow SET (kwh_avg, count, updated) = (((old.kwh_avg * old.count + new.kwh) / (old.count + new.count)), old.count + new.count, CURRENT_TIMESTAMP) FROM old, new WHERE hour = {0} AND dow = {2};""".format(ophour, endtime, dow)
    cursor.execute(query)
    query = """WITH old AS (SELECT count, kwh_avg, updated, season FROM electricity_statistics.electricity_statistics_hourly_season WHERE hour = {0} AND season = (SELECT season FROM meteorological_season WHERE doy = DATE_PART('doy', '{1}'::DATE))), new AS (SELECT COUNT(DISTINCT measurement_time::DATE), COALESCE(SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.), 0) AS kwh FROM electricity.electricity_measurements e INNER JOIN meteorological_season m ON date_part('doy', measurement_time)=m.doy, old WHERE measurement_time > old.updated AND measurement_time <= '{1}' AND DATE_PART('hour', measurement_time) = {0} AND m.season = old.season) UPDATE electricity_statistics.electricity_statistics_hourly_season AS e SET (kwh_avg, count, updated) = (((old.kwh_avg * old.count + new.kwh) / (old.count + new.count)), old.count + new.count, CURRENT_TIMESTAMP) FROM old, new WHERE hour = {0} AND e.season = old.season;""".format(ophour, endtime)
    cursor.execute(query)
    query = """WITH old AS (SELECT count, kwh_avg, updated, season FROM electricity_statistics.electricity_statistics_hourly_dow_season WHERE hour = {0} AND dow = {2} AND season = (SELECT season FROM meteorological_season WHERE doy = DATE_PART('doy', '{1}'::DATE))), new AS (SELECT COUNT(DISTINCT measurement_time::DATE), COALESCE(SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.), 0) AS kwh FROM electricity.electricity_measurements e INNER JOIN meteorological_season m ON date_part('doy', measurement_time)=m.doy, old WHERE measurement_time > old.updated AND measurement_time <= '{1}' AND DATE_PART('hour', measurement_time) = {0} AND DATE_PART('dow', measurement_time) = {2} AND m.season = old.season) UPDATE electricity_statistics.electricity_statistics_hourly_dow_season AS e SET (kwh_avg, count, updated) = (((old.kwh_avg * old.count + new.kwh) / (old.count + new.count)), old.count + new.count, CURRENT_TIMESTAMP) FROM old, new WHERE hour = {0} AND dow = {2} AND e.season = old.season;""".format(ophour, endtime, dow)
    cursor.execute(query)
    db.commit()
    query = """INSERT INTO electricity_statistics.electricity_sums_hourly (sum_date, hour, kwh) VALUES ('{0}', {1}, {2});""".format(opdate.strftime('%Y-%m-%d'), ophour, kwh)
    try:
        cursor.execute(query)
    except:
        print("Hourly sum already updated.")
    db.commit()
    # Predict the actual usage based on measured usage
    query = """SELECT SUM((watts_ch1) * tdiff / 60 / 60 / 1000.) AS kwh_ch1, SUM((watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh_ch2, SUM((watts_ch3) * tdiff / 60 / 60 / 1000.) AS kwh_ch3, MIN(CASE s.season WHEN 'winter' THEN 0 WHEN 'spring' then 1 WHEN 'summer' THEN 2 WHEN 'fall' THEN 3 END) AS season, COUNT(*) AS measurement_count, MAX(tdiff) AS max_tdiff FROM electricity.electricity_measurements LEFT JOIN weather_data.meteorological_season s ON s.doy=DATE_PART('doy', measurement_time) WHERE measurement_time > '{0}' AND measurement_time <= '{1}' AND date_part('hour', measurement_time) = {2};""".format(starttime, endtime, ophour)
    cursor.execute(query)
    kwh_ch1, kwh_ch2, kwh_ch3, season, measurement_count, max_tdiff = cursor.fetchone()
    df = pd.DataFrame([(hour, kwh_ch1, kwh_ch2, kwh_ch3, season, measurement_count, max_tdiff)], columns=['hour', 'kwh_ch1', 'kwh_ch2', 'kwh_ch3', 'season', 'measurement_count', 'max_tdiff'])
    pred = rf.predict(df)
    query = """UPDATE electricity_statistics.electricity_sums_hourly SET kwh_modeled = {0} WHERE sum_date = '{1}' AND hour = {2};""".format(pred[0], opdate.strftime('%Y-%m-%d'), ophour)
    cursor.execute(query)
    db.commit()

def day_query(now, nowdow, opdate, dow, endtime, rundate, reset):
    if not rundate:
        query = """UPDATE electricity.electricity_usage_dow SET (kwh, complete, updated) = (0, 'no', '{0} 00:00:00') WHERE dow = {1};""".format(now.strftime('%Y-%m-%d'), nowdow)
        cursor.execute(query)
        query = """UPDATE electricity.electricity_usage_doy SET (kwh, complete, updated) = (0, 'no', '{0} 00:00:00') WHERE month = {1} AND day = {2};""".format(now.strftime('%Y-%m-%d'), now.month, now.day)
        cursor.execute(query)
        db.commit()
        query = """UPDATE electricity_statistics.electricity_statistics_doy SET (previous_year, current_year) = (current_year, NULL) WHERE month = {0} and day = {1}""".format(now.month, now.day)
        cursor.execute(query)
        db.commit()
    query = """SELECT 't' = ANY(array_agg(tdiff * (watts_ch1 + watts_ch2) > 0)) FROM electricity.electricity_measurements WHERE measurement_time >= '{0}' AND measurement_time < '{1}' AND tdiff >= 300 and tdiff * (watts_ch1 + watts_ch2) > 0;""".format(opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'))
    cursor.execute(query)
    data = cursor.fetchall()
    maxint = data[0][0]
    if not maxint:
        complete = 'yes'
    else:
        complete = 'no'
    query = """UPDATE electricity.electricity_usage_dow SET kwh = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity.electricity_measurements WHERE measurement_time >= '{0}' AND measurement_time < '{1}'), complete = '{3}', updated = CURRENT_TIMESTAMP WHERE dow = {2} RETURNING kwh;""".format(opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'), dow, complete)
    cursor.execute(query)
    kwh = cursor.fetchall()[0][0]
    query = """UPDATE electricity.electricity_usage_doy SET (kwh, complete, updated) = ({0}, '{1}', CURRENT_TIMESTAMP) WHERE month = {2} AND day = {3};""".format(kwh, complete, opdate.month, opdate.day)
    cursor.execute(query)
    db.commit()
    query = """WITH old AS (SELECT count, kwh_avg, updated FROM electricity_statistics.electricity_statistics_dow WHERE dow = {0}), new AS (SELECT COUNT(DISTINCT measurement_time::DATE), COALESCE(SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.), 0) AS kwh FROM electricity.electricity_measurements e, old WHERE measurement_time > old.updated AND measurement_time <= '{1}' AND DATE_PART('dow', measurement_time) = {0}) UPDATE electricity_statistics.electricity_statistics_dow AS e SET (kwh_avg, count, updated) = (((old.kwh_avg * old.count + new.kwh) / (old.count + new.count)), old.count + new.count, CURRENT_TIMESTAMP) FROM old, new WHERE dow = {0} RETURNING e.kwh_avg;""".format(dow, endtime)
    cursor.execute(query)
    kwh_avg_dow = cursor.fetchall()[0][0]
    query = """WITH old AS (SELECT count, kwh_avg, updated, season FROM electricity_statistics.electricity_statistics_dow_season WHERE dow = {0} AND season = (SELECT season FROM meteorological_season WHERE doy = DATE_PART('doy', '{1}'::DATE))), new AS (SELECT COUNT(DISTINCT measurement_time::DATE), COALESCE(SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.), 0) AS kwh FROM electricity.electricity_measurements e INNER JOIN meteorological_season m ON date_part('doy', measurement_time)=m.doy, old WHERE measurement_time > old.updated AND measurement_time <= '{1}' AND DATE_PART('dow', measurement_time) = {0} AND m.season = old.season) UPDATE electricity_statistics.electricity_statistics_dow_season AS e SET (kwh_avg, count, updated) = (((old.kwh_avg * old.count + new.kwh) / (old.count + new.count)), old.count + new.count, CURRENT_TIMESTAMP) FROM old, new WHERE dow = {0} AND e.season = old.season RETURNING e.kwh_avg;""".format(dow, endtime)
    cursor.execute(query)
    kwh_avg_dow_season = cursor.fetchall()[0][0]
    query = """UPDATE electricity_statistics.electricity_statistics_doy SET (current_year, kwh_avg, count, updated) = ({0}, ({0} + (kwh_avg * count)) / (count + 1), count + 1, CURRENT_TIMESTAMP) WHERE month = {1} AND day = {2} RETURNING kwh_avg, previous_year;""".format(kwh, opdate.month, opdate.day)
    cursor.execute(query)
    kwh_avg_doy, previous_year = cursor.fetchall()[0]
    db.commit()
    query = """INSERT INTO electricity_statistics.electricity_sums_daily (sum_date, kwh) VALUES ('{0}', {1});""".format(opdate.strftime('%Y-%m-%d'), kwh)
    cursor.execute(query)
    db.commit()
    query = """INSERT INTO electricity_statistics.electricity_statistics_daily_minimum (measurement_date, watts) SELECT '{0}'::date, min(watts_ch1 + watts_ch2) AS watts FROM electricity.electricity_measurements WHERE measurement_time >= '{0} 00:00:00' and measurement_time::date = '{0}';""".format(opdate.strftime('%Y-%m-%d'))
    cursor.execute(query)
    db.commit()
    return (kwh, kwh_avg_dow, kwh_avg_dow_season, kwh_avg_doy, previous_year)

def month_query(now, opmonth, year, reset):
    if reset:
        query = """UPDATE electricity.electricity_usage_monthly SET (kwh, complete, updated) = (0, 'no', '{0} 00:00:00') WHERE month = {1};""".format(now.strftime('%Y-%m-%d'), now.month)
        cursor.execute(query)
        db.commit()
    query = """SELECT date_part('day', min(measurement_time)) = 1, date_part('day', max(measurement_time)) = num_days({0},{1}), max(tdiff) < 300  FROM electricity.electricity_measurements WHERE date_part('month', measurement_time) = {1} AND date_part('year', measurement_time) = {2};""".format(year, opmonth, year)
    cursor.execute(query)
    data = cursor.fetchall()
    mmin, mmax, maxint = zip(*data)
    if mmin[0] and mmax[0] and maxint[0]:
        complete = 'yes'
    else:
        complete = 'no'
    query = """UPDATE electricity.electricity_usage_monthly SET kwh = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity.electricity_measurements WHERE date_part('month', measurement_time) = {0} AND date_part('year', measurement_time) = {1}), complete = '{2}', updated = CURRENT_TIMESTAMP WHERE month = {0} RETURNING kwh;""" % (opmonth, year, complete)
    cursor.execute(query)
    kwh = cursor.fetchall()[0][0]
    db.commit()
    query = """SELECT previous_year FROM electricity_statistics.electricity_statistics_monthly WHERE month = {0}""".format(opmonth)
    cursor.execute(query)
    prevkwh = cursor.fetchall()[0][0]
    query = """UPDATE electricity_statistics.electricity_statistics_monthly SET (count, kwh_avg, previous_year, updated) = (count + 1,  ({0} + (kwh_avg * count)) / (count + 1), {0}, CURRENT_TIMESTAMP) WHERE month = {1} RETURNING kwh_avg""".format(kwh, opmonth)
    cursor.execute(query)
    kwh_avg = cursor.fetchall()[0][0]
    db.commit()
    query = """INSERT INTO energy_statistics.electricity_sums_monthly (year, month, kwh) VALUES ({0}, {1}, {2});""".format(year, opmonth, kwh)
    cursor.execute(query)
    db.commit()
    return (kwh, kwh_avg, prevkwh)





# Main stuff here
now = pytz.utc.localize(datetime.datetime.utcnow()).astimezone(pytz.timezone(tz))

if args.mode == 'hour':
    print('Hourly')
    # Load additional modules needed for electricity correction
    from sklearn.ensemble import RandomForestRegressor
    from sklearn.externals import joblib
    import pandas as pd
    # Load the model file
    rf = joblib.load('{0}/hourly_correction_model.pkl'.format(pickledir))
    if args.rundate and args.runhour:
        res = hour_calc(now, args.rundate, args.runhour)
    else:
        res = hour_calc(now)
    hour, now, ophour, opdate, dow, starttime, endtime, reset = res
    hour_query(now, opdate, hour, ophour, starttime, endtime, dow, reset)
elif args.mode == 'day':
    print('Daily')
    if args.rundate:
        res = day_calc(now, args.rundate)
    else:
        res = day_calc(now)
    opdate, now, dow, nowdow, starttime, endtime, reset = res
    day_query(now, nowdow, opdate, dow, endtime, None, reset)
elif args.mode == 'month':
    print('Monthly')
    if args.runmonth:
        res = month_calc(now.rundate)
    else:
        res = month_calc(now)
    opmonth, month, year, startime, endtime, reset = res
    print(month_query(now, opmonth, year, reset))
elif args.mode == 'year':
    print('Yearly')


# Close DB
cursor.close()
db.close()
