#!/usr/bin/python

import argparse, ConfigParser, datetime, psycopg2, pytz

# Allow the script to be run on a specific day of the week
p = argparse.ArgumentParser(prog="generate_summary_dow.py")
p.add_argument('-date', dest="rundate", required=False, help="The date to run in format 'YYYY-MM-DD'.")
args = p.parse_args()

# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read('/home/jessebishop/.pyconfig')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')
dbport = config.get('pidb', 'DBPORT')
mytz = pytz.timezone(config.get('location', 'TZ'))
utctz = pytz.utc

# Connect to the database
db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
cursor = db.cursor()

# Set the appropriate opdate 
if args.rundate:
    opdate = datetime.datetime.strptime(args.rundate, '%Y-%m-%d')
    now = opdate + datetime.timedelta(1)
else:
    now = datetime.datetime.now()
    opdate = now - datetime.timedelta(1)

now = mytz.localize(now)
opdate = mytz.localize(opdate)

# Set start and end timezone
tzstart = mytz.localize(datetime.datetime.combine(opdate.date(), datetime.time(0,0,0))).strftime('%Z')
tzend = mytz.localize(datetime.datetime.combine(opdate.date(), datetime.time(23,59,59))).strftime('%Z')
nowdow = now.isoweekday()
if nowdow == 7:
    nowdow = 0

dow = opdate.isoweekday()
if dow == 7:
    dow = 0

# Update the current period to be ready for incremental updates to speed up querying if running as cron
if not args.rundate:
    query = """UPDATE electricity_usage_dow SET (kwh, complete, timestamp) = (0, 'no', '{0} 00:00:00') WHERE dow = {1};""".format(now.strftime('%Y-%m-%d'), nowdow)
    cursor.execute(query)
    db.commit()

# Check to see if the data are complete
query = """SELECT 't' = ANY(array_agg(tdiff * (watts_ch1 + watts_ch2) > 0)) FROM electricity_measurements WHERE measurement_time >= '%s' AND measurement_time < '%s' AND tdiff >= 300 and tdiff * (watts_ch1 + watts_ch2) > 0;""" % (opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'))
cursor.execute(query)
data = cursor.fetchall()
maxint = data[0][0]
if not maxint:
    complete = 'yes'
else:
    complete = 'no'

# Compute the period metrics. For now, do the calculation on the entire record. Maybe in the future, we'll trust the incremental updates.
query = """UPDATE electricity_usage_dow SET kwh = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE measurement_time AT TIME ZONE '{0}' >= '{1}' AND measurement_time AT TIME ZONE '{2}' < '{3}') WHERE dow = {4} RETURNING kwh;""".format(tzstart, opdate.strftime('%Y-%m-%d'), tzend, now.strftime('%Y-%m-%d'), dow)
cursor.execute(query)
kwh = cursor.fetchall()[0][0]
#query = """UPDATE electricity_usage_dow SET kwh_avg = (SELECT AVG(kwh) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE tdiff <= 86400 AND measurement_time >= '2013-03-22' AND date_part('dow', measurement_time) = %s GROUP BY date_part('year', measurement_time), date_part('doy', measurement_time)) AS x) WHERE dow = %s RETURNING kwh_avg;""" % (dow, dow)
query = """UPDATE electricity_usage_dow SET kwh_avg = (SELECT (old + %s) / (count + 1) FROM (SELECT kwh_avg * count AS old, count FROM energy_statistics.electricity_statistics_dow WHERE dow = %s) AS x) WHERE dow = %s RETURNING kwh_avg""" % (kwh, dow, dow)
cursor.execute(query)
kwh_avg = cursor.fetchall()[0][0]
query = """UPDATE energy_statistics.electricity_statistics_dow SET (count, kwh_avg, timestamp) = (count + 1, %s, CURRENT_TIMESTAMP) WHERE dow = %s""" % (kwh_avg, dow)
cursor.execute(query)
# Seasonal averaging
query = """UPDATE energy_statistics.electricity_statistics_dow_season SET count=count + 1, kwh_avg=y.avg, timestamp=CURRENT_TIMESTAMP FROM (SELECT ((kwh_avg * count) + %s) / (count + 1) AS avg FROM energy_statistics.electricity_statistics_dow_season WHERE dow = %s AND season = (SELECT season FROM meteorological_season WHERE doy = date_part('doy', '%s'::date))) AS y WHERE dow = %s AND season = (SELECT season FROM meteorological_season WHERE doy = date_part('doy', '%s'::date)) RETURNING kwh_avg, season;""" % (kwh, dow, opdate.strftime('%Y-%m-%d'), dow, opdate.strftime('%Y-%m-%d'))
cursor.execute(query)
kwh_avg_season, season = cursor.fetchall()[0]
query = """UPDATE electricity_usage_dow SET complete = '%s' WHERE dow = %s;""" % (complete, dow)
cursor.execute(query)
if args.rundate:
    query = """UPDATE electricity_usage_dow SET timestamp = '%s 00:00:01' WHERE dow = %s;""" % (now.strftime('%Y-%m-%d'), dow)
else:
    query = """UPDATE electricity_usage_dow SET timestamp = CURRENT_TIMESTAMP WHERE dow = %s;""" % (dow)
cursor.execute(query)

# Update sums table
query = """INSERT INTO energy_statistics.electricity_sums_daily (date, kwh) VALUES ('%s', %s);""" % (opdate.strftime('%Y-%m-%d'), kwh)
cursor.execute(query)

# Now finish it off
cursor.close()
db.commit()
db.close()

if not args.rundate:
    from tweet import *
    if kwh > kwh_avg:
        s1 = "more"
    else:
        s1 = "less"
    if kwh > kwh_avg_season:
        s2 = "more"
    else:
        s2 = "less"
    if s1 == s2:
        j = "and"
    else:
        j = "but"
    status = """You used {0} electricity yesterday than your average use for a {1} {2} {3} than your average for a {1} in the {4}!""".format(s1, opdate.strftime('%A'), j, s2, season)
    tweet(status)
