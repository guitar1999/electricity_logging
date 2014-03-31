#!/usr/bin/python

import datetime, psycopg2

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
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

# Compute the period metrics. For now, do the calculation on the entire record. Maybe in the future, we'll trust the incremental updates.
query = """UPDATE electricity_usage_monthly SET kwh = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE date_part('month', measurement_time) = %s AND date_part('year', measurement_time) = %s) WHERE month = %s RETURNING kwh;""" % (opmonth, year, opmonth)
cursor.execute(query)
kwh = cursor.fetchall()[0][0]
query = """UPDATE electricity_usage_monthly SET kwh_avg = (SELECT AVG(kwh) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE date_part('month', measurement_time) = %s GROUP BY date_part('year', measurement_time)) AS x) WHERE month = %s RETURNING kwh_avg;""" % (opmonth, opmonth)
cursor.execute(query)
kwh_avg = cursor.fetchall()[0][0]
query = """UPDATE electricity_usage_monthly SET complete = '%s' WHERE month = %s;""" % (complete, opmonth)
cursor.execute(query)
query = """UPDATE electricity_usage_monthly SET timestamp = CURRENT_TIMESTAMP WHERE month = %s;""" % (opmonth)
cursor.execute(query)

# And finish it off
cursor.close()
db.commit()
db.close()

