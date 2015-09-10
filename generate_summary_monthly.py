#!/usr/bin/python

import calendar, ConfigParser, datetime, psycopg2
from tweet import *

# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read('/home/jessebishop/.pyconfig')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')
dbport = config.get('pidb', 'DBPORT')

# Connect to the database
db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
cursor = db.cursor()

now = datetime.datetime.now()
month = now.month
opmonth = month - 1
year = now.year
if opmonth == 0:
    opmonth = 12
if opmonth == 12:
    year = year - 1

# Update the current period to be ready for incremental updates to speed up querying
query = """UPDATE electricity_usage_monthly SET (kwh, complete, timestamp) = (0, 'no', '%s 00:00:00') WHERE month = %s;""" % (now.strftime('%Y-%m-%d'), month)
cursor.execute(query)
db.commit()

query = """SELECT date_part('day', min(measurement_time)) = 1, date_part('day', max(measurement_time)) = num_days(%s,%s), max(tdiff) < 300  FROM electricity_measurements WHERE date_part('month', measurement_time) = %s AND date_part('year', measurement_time) = %s;""" % (year, opmonth, opmonth, year)
cursor.execute(query)
data = cursor.fetchall()
mmin, mmax, maxint = zip(*data)
if mmin[0] and mmax[0] and maxint[0]:
    complete = 'yes'
else:
    complete = 'no'

# Get the monthly total for the previous year
query = """SELECT previous_year FROM energy_statistics.electricity_statistics_monthly WHERE month = {0}""".format(opmonth)
cursor.execute(query)
prevkwh = cursor.fetchall()[0][0]
# Compute the period metrics. For now, do the calculation on the entire record. Maybe in the future, we'll trust the incremental updates.
query = """UPDATE electricity_usage_monthly SET kwh = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE date_part('month', measurement_time) = %s AND date_part('year', measurement_time) = %s) WHERE month = %s RETURNING kwh;""" % (opmonth, year, opmonth)
cursor.execute(query)
kwh = cursor.fetchall()[0][0]
#query = """UPDATE electricity_usage_monthly SET kwh_avg = (SELECT AVG(kwh) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE date_part('month', measurement_time) = %s GROUP BY date_part('year', measurement_time)) AS x) WHERE month = %s RETURNING kwh_avg;""" % (opmonth, opmonth)
query = """UPDATE electricity_usage_monthly SET kwh_avg = (SELECT (old + %s) / (count + 1) FROM (SELECT kwh_avg * count AS old, count FROM energy_statistics.electricity_statistics_monthly WHERE month = %s) AS x) WHERE month = %s RETURNING kwh_avg""" % (kwh, opmonth, opmonth)
cursor.execute(query)
kwh_avg = cursor.fetchall()[0][0]
query = """UPDATE energy_statistics.electricity_statistics_monthly SET (count, kwh_avg, previous_year, timestamp) = (count + 1, %s, %s, CURRENT_TIMESTAMP) WHERE month = %s""" % (kwh_avg, kwh, opmonth)
cursor.execute(query)
query = """UPDATE electricity_usage_monthly SET complete = '%s' WHERE month = %s;""" % (complete, opmonth)
cursor.execute(query)
query = """UPDATE electricity_usage_monthly SET timestamp = CURRENT_TIMESTAMP WHERE month = %s;""" % (opmonth)
cursor.execute(query)

# See if we've set a record. Always do this before sums table so you're not comparing against current month!
query = """SELECT CASE WHEN {0} > (SELECT max(kwh) FROM energy_statistics.electricity_sums_monthly) THEN 'max' WHEN {0} < (SELECT min(kwh) FROM energy_statistics.electricity_sums_monthly) THEN 'min' ELSE 'none' END;""".format(kwh)
cursor.execute(query)
userecord = cursor.fetchall()[0][0]
query = """SELECT CASE WHEN {0} > (SELECT max(kwh) FROM energy_statistics.electricity_sums_monthly WHERE month = {1}) THEN 'max' WHEN {0} < (SELECT min(kwh) FROM energy_statistics.electricity_sums_monthly WHERE month = {1}) THEN 'min' ELSE 'none' END;""".format(kwh, opmonth)
cursor.execute(query)
userecord_month = cursor.fetchall()[0][0]


# Update the sums table
query = """INSERT INTO energy_statistics.electricity_sums_monthly (year, month, kwh) VALUES (%s, %s, %s);""" % (year, opmonth, kwh)
cursor.execute(query)

# And finish it off
cursor.close()
db.commit()
db.close()

# Now tweet about it!
if kwh > kwh_avg:
    s1 = "more"
    a1 = kwh - kwh_avg
else:
    s1 = "less"
    a1 = kwh_avg - kwh
if kwh > prevkwh:
    s2 = "more"
    a2 = kwh - prevkwh
else:
    s2 = "less"
    a2 = prevkwh - kwh
if s1 == s2:
    j = "and"
else:
    j = "but"
status = """You used {0} kwh {1} last month than your average {2} usage {3} {4} kwh {5} than you used in {2} {6}.""".format(round(a1, 2), s1, calendar.month_name[opmonth], j, round(a2, 2), s2, year - 1)
tweet(status)

# Now tweet about any records that may have been set
usestring = """Your monthly useage of {0} kwh""".format(round(kwh, 1))
if userecord != 'none':
    if userecord == 'min':
        recordtext = 'is less'
    else:
        recordtext = 'is more'
    status = """{0} in {1} {2} than any previous month ever!""".format(usestring, calendar.month_name[opmonth], recordtext)
elif userecord == 'none' and userecord_month != 'none':
    if userecord_month == 'min':
        month_recordtext = "is less"
    elif userrecord_month == 'max':
        month_recordtext = "is more"
    status = """{0} {1} than any previous {2}!""".format(usestring, month_recordtext, calendar.month_name[opmonth])
    tweet(status)
