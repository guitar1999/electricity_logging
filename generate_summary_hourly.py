#!/usr/bin/python

import argparse, ConfigParser, datetime, psycopg2

# Allow the script to be run on a specific hour day of the week
p = argparse.ArgumentParser(prog="generate_summary_hourly.py")
p.add_argument('-hour', dest="runhour", required=False, help="The hour to run.")
p.add_argument('-date', dest="rundate", required=False, help="The date to run in format 'YYYY-MM-DD'.")
args = p.parse_args()

# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read('/home/jessebishop/.pyconfig')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')

# Connect to the database
db = psycopg2.connect(host=dbhost, database=dbname, user=dbuser)
cursor = db.cursor()

if args.runhour:
    if args.runhour != '23':
        hour = int(args.runhour) + 1
        now = datetime.datetime.strptime(args.rundate, '%Y-%m-%d')
    else:
        hour = 0
        now = datetime.datetime.strptime(args.rundate, '%Y-%m-%d') + datetime.timedelta(1)
else:
    now = datetime.datetime.now()
    hour = now.hour

if hour == 0:
    ophour = 23
    opdate = now - datetime.timedelta(1)
else:
    ophour = hour - 1
    opdate = now
dow = opdate.isoweekday()
# Make sunday 0 to match postgres style rather than python style
if dow == 7:
    dow = 0

# Now update the current period to be ready for incremental updates to speed up querying
if not args.runhour:
    query = """UPDATE electricity_usage_hourly SET (kwh, complete, timestamp) = (0, 'no', '%s:00:00') WHERE hour = %s;""" % (now.strftime('%Y-%m-%d %H'), hour)
    cursor.execute(query)
    db.commit()

# Check to see if the data are complete
query = """SELECT max(tdiff) < 300  FROM electricity_measurements WHERE measurement_time > '%s' AND date_part('hour', measurement_time) = %s;""" % (opdate.strftime('%Y-%m-%d'), ophour)
cursor.execute(query)
data = cursor.fetchall()
maxint = data[0][0]
if maxint:
    complete = 'yes'
else:
    complete = 'no'


#Compute the period metrics. For now, do the calculation on the entire record. Maybe in the future, we'll trust the incremental updates.
query = """UPDATE electricity_usage_hourly SET kwh = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE measurement_time > '%s' AND date_part('hour', measurement_time) = %s) WHERE hour = %s RETURNING kwh;""" % (opdate.strftime('%Y-%m-%d'), ophour, ophour)
cursor.execute(query)
kwh = cursor.fetchall()[0][0]
#query = """UPDATE electricity_usage_hourly SET kwh_avg = (SELECT AVG(kwh) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE tdiff <= 3600 AND measurement_time >= '2013-03-22' AND date_part('hour', measurement_time) = %s GROUP BY date_part('doy', measurement_time)) AS x) WHERE hour = %s;""" % (ophour, ophour)
query = """UPDATE electricity_usage_hourly SET kwh_avg = (SELECT (old + %s) / (count + 1) FROM (SELECT kwh_avg * count AS old, count FROM energy_statistics.electricity_statistics_hourly WHERE hour = %s) AS x) WHERE hour = %s RETURNING kwh_avg""" % (kwh, ophour, ophour)
cursor.execute(query)
kwh_avg = cursor.fetchall()[0][0]
query = """UPDATE energy_statistics.electricity_statistics_hourly SET (count, kwh_avg, timestamp) = (count + 1, %s, CURRENT_TIMESTAMP) WHERE hour = %s""" % (kwh_avg, ophour)
cursor.execute(query)
#query = """UPDATE electricity_usage_hourly SET kwh_avg_dow = (SELECT AVG(kwh) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE tdiff <= 3600 AND measurement_time >= '2013-03-22' AND date_part('hour', measurement_time) = %s AND date_part('dow', measurement_time) = %s GROUP BY date_part('doy', measurement_time)) AS x) WHERE hour = %s;""" % (ophour, dow, ophour)
query = """UPDATE electricity_usage_hourly SET kwh_avg_dow = (SELECT (old + %s) / (count + 1) FROM (SELECT kwh_avg_dow * count AS old, count FROM energy_statistics.electricity_statistics_hourly_dow WHERE hour = %s AND dow = %s) AS x) WHERE hour = %s RETURNING kwh_avg_dow""" % (kwh, ophour, dow, ophour)
cursor.execute(query)
kwh_avg_dow = cursor.fetchall()[0][0]
query = """UPDATE energy_statistics.electricity_statistics_hourly_dow SET (count, kwh_avg_dow, timestamp) = (count + 1, %s, CURRENT_TIMESTAMP) WHERE hour = %s AND dow = %s""" % (kwh_avg_dow, ophour, dow)
cursor.execute(query)
# Seasonal averaging
query = """UPDATE energy_statistics.electricity_statistics_hourly_season SET count=count + 1, kwh_avg_season=y.avg, timestamp=CURRENT_TIMESTAMP FROM (SELECT ((kwh_avg_season * count) + %s) / (count + 1) AS avg FROM energy_statistics.electricity_statistics_hourly_season WHERE hour = %s AND season = (SELECT season FROM meteorological_season WHERE doy = date_part('doy', '%s'::date))) AS y WHERE hour = %s AND season = (SELECT season FROM meteorological_season WHERE doy = date_part('doy', '%s'::date));""" % (kwh, ophour, opdate.strftime('%Y-%m-%d'), ophour, opdate.strftime('%Y-%m-%d'))
cursor.execute(query)
# Seasonal DOW averaging
query = """UPDATE energy_statistics.electricity_statistics_hourly_dow_season SET count=count + 1, kwh_avg_dow_season=y.avg, timestamp=CURRENT_TIMESTAMP FROM (SELECT ((kwh_avg_dow_season * count) + %s) / (count + 1) AS avg FROM energy_statistics.electricity_statistics_hourly_dow_season WHERE hour = %s AND season = (SELECT season FROM meteorological_season WHERE doy = date_part('doy', '%s'::date)) AND dow = %s) AS y WHERE hour = %s AND season = (SELECT season FROM meteorological_season WHERE doy = date_part('doy', '%s'::date)) AND dow = %s;""" % (kwh, ophour, opdate.strftime('%Y-%m-%d'), dow, ophour, opdate.strftime('%Y-%m-%d'), dow)
cursor.execute(query)


# Older queries
query = """UPDATE electricity_usage_hourly SET complete = '%s' WHERE hour = %s;""" % (complete, ophour)
cursor.execute(query)
if args.rundate:
    query = """UPDATE electricity_usage_hourly SET timestamp = '%s %s:00:01' WHERE hour = %s;""" % (now.strftime('%Y-%m-%d'), hour, ophour)
else:
    query = """UPDATE electricity_usage_hourly SET timestamp = CURRENT_TIMESTAMP WHERE hour = %s;""" % (ophour)
cursor.execute(query)

# And finish it off
db.commit()
cursor.close()
db.close()
