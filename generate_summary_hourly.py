#!/usr/bin/python

import datetime, psycopg2

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()

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
query = """UPDATE electricity_usage_hourly SET kwh = (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE measurement_time > '%s' AND date_part('hour', measurement_time) = %s) WHERE hour = %s;""" % (opdate.strftime('%Y-%m-%d'), ophour, ophour)
cursor.execute(query)
query = """UPDATE electricity_usage_hourly SET kwh_avg = (SELECT AVG(kwh) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE measurement_time >= '2013-03-22' AND date_part('hour', measurement_time) = %s GROUP BY date_part('doy', measurement_time)) AS x) WHERE hour = %s;""" % (ophour, ophour)
cursor.execute(query)
query = """UPDATE electricity_usage_hourly SET kwh_avg_dow = (SELECT AVG(kwh) FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE measurement_time >= '2013-03-22' AND date_part('hour', measurement_time) = %s AND date_part('dow', measurement_time) = %s GROUP BY date_part('doy', measurement_time)) AS x) WHERE hour = %s;""" % (ophour, dow, ophour)
cursor.execute(query)
query = """UPDATE electricity_usage_hourly SET complete = '%s' WHERE hour = %s;""" % (complete, ophour)
cursor.execute(query)
query = """UPDATE electricity_usage_hourly SET timestamp = CURRENT_TIMESTAMP WHERE hour = %s;""" % (ophour)
cursor.execute(query)

# Now update the current period to be ready for incremental updates to speed up querying
query = """UPDATE electricity_usage_hourly SET (kwh, complete, timestamp) = (0, 'no', '%s:00:00') WHERE hour = %s;""" % (now.strftime('%Y-%m-%d %H'), hour)
cursor.execute(query)


# And finish it off
db.commit()
cursor.close()
db.close()

