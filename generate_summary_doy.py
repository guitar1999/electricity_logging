#!/usr/bin/python

import argparse, ConfigParser, datetime, psycopg2
from tweet import *

# Allow the script to be run on a specific day of the week
p = argparse.ArgumentParser(prog="generate_summary_doy.py")
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


if args.rundate:
    opdate = datetime.datetime.strptime(args.rundate, '%Y-%m-%d')
    now = opdate + datetime.timedelta(1)
    timestamp = "{0} 00:00:01".format(now.strftime('%Y-%m-%d'))
else:
    now = datetime.datetime.now()
    opdate = now - datetime.timedelta(1)
    timestamp = now.strftime('%Y-%m-%d %H:%M:%S')

doy = opdate.timetuple().tm_yday
dow = opdate.isoweekday()
month = opdate.month
day = opdate.day
# Make sunday 0 to match postgres style rather than python style
if dow == 7:
    dow = 0


# Now update the current period to be ready for incremental updates to speed up querying and
# and move the current to previous for the current day (now).
if not args.rundate:
    query = """UPDATE electricity_usage_doy SET (kwh, complete, timestamp) = (0, 'no', '{0} 00:00:00') WHERE month = {1} AND day = {2};""".format(now.strftime('%Y-%m-%d'), now.month, now.day)
    cursor.execute(query)
    db.commit()
    query = """UPDATE electricity_statistics_doy SET (previous_year, current_year) = (current_year, NULL) WHERE month = {0} and day = {1}""".format(now.month, now.day)
    cursor.execute(query)
    db.commit()

# Check to see if the data are complete
query = """SELECT 't' = ANY(array_agg(tdiff * (watts_ch1 + watts_ch2) > 0)) FROM electricity_measurements WHERE measurement_time >= '{0}' AND measurement_time < '{1}' AND tdiff >= 300 and tdiff * (watts_ch1 + watts_ch2) > 0;""".format(opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'))
cursor.execute(query)
data = cursor.fetchall()
maxint = data[0][0]
if not maxint:
    complete = 'yes'
else:
    complete = 'no'

#Compute the period metrics. For now, do the calculation on the entire record. Maybe in the future, we'll trust the incremental updates.
query = """UPDATE electricity_usage_doy SET kwh = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE measurement_time >= '{0}' AND measurement_time < '{1}') WHERE month = {2} AND day = {3} RETURNING kwh;""".format(opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'), month, day)
cursor.execute(query)
kwh = cursor.fetchall()[0][0]
# Put kwh in current_year in statistics table
query = """UPDATE electricity_statistics_doy SET (current_year, kwh_avg, count, timestamp) = ({0}, ({0} + (kwh_avg * count)) / (count + 1), count + 1, '{1}') WHERE month = {2} AND day = {3} RETURNING kwh_avg, previous_year;""".format(kwh, timestamp, month, day)
cursor.execute(query)
kwh_avg, previous_year = cursor.fetchall()[0]
# Update the rest of the usage table
query = """UPDATE electricity_usage_doy SET (kwh_avg, complete, timestamp) = ({0}, '{1}', '{2}') WHERE month = {3} AND day = {4};""".format(kwh_avg, complete, timestamp, month, day)
cursor.execute(query)
# Update the minimum table
query = """INSERT INTO electricity_statistics_daily_minimum (measurement_date, watts) SELECT '{0}'::date, min(watts_ch1 + watts_ch2) AS watts FROM electricity_measurements WHERE measurement_time >= '{0} 00:00:00' and measurement_time::date = '{0}';""".format(opdate.strftime('%Y-%m-%d'))
cursor.execute(query)

# And finish it off
cursor.close()
db.commit()
db.close()

# Tweet some info
if not args.rundate:
    if kwh > previous_year:
        s1 = "more"
    else:
        s1 = "less"
    pct_diff = abs(round((((kwh * 1.0) - previous_year) / previous_year * 100), 2))
    status = """You used {0}% {1} electricity than you did on {2}-{3}-{4}""".format(pct_diff, s1, opdate.year, month, day)
    tweet(status)
