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
query = """SELECT max(tdiff) < 300  FROM temp_electricity WHERE time > '%s' AND date_part('hour', time) = %s;""" % (opdate.strftime('%Y-%m-%d'), ophour)
cursor.execute(query)
data = cursor.fetchall()
maxint = data[0][0]
if maxint:
    complete = 'yes'
else:
    complete = 'no'

query = """UPDATE electricity_usage_hourly SET kwh = (SELECT SUM(watts * tdiff / 60 / 60 / 1000.) AS kwh FROM temp_electricity WHERE time > '%s' AND date_part('hour', time) = %s) WHERE hour = %s;""" % (opdate.strftime('%Y-%m-%d'), ophour, ophour)
cursor.execute(query)
query = """UPDATE electricity_usage_hourly SET kwh_avg = (SELECT AVG(kwh) FROM (SELECT SUM(watts * tdiff / 60 / 60 / 1000.) AS kwh FROM temp_electricity WHERE date_part('hour', time) = %s GROUP BY date_part('doy', time)) AS x) WHERE hour = %s;""" % (ophour, ophour)
cursor.execute(query)
query = """UPDATE electricity_usage_hourly SET kwh_avg_dow = (SELECT AVG(kwh) FROM (SELECT SUM(watts * tdiff / 60 / 60 / 1000.) AS kwh FROM temp_electricity WHERE date_part('hour', time) = %s AND date_part('dow', time) = %s GROUP BY date_part('doy', time)) AS x) WHERE hour = %s;""" % (ophour, dow, ophour)
cursor.execute(query)
query = """UPDATE electricity_usage_hourly SET complete = '%s' WHERE hour = %s;""" % (complete, ophour)
cursor.execute(query)
db.commit()
cursor.close()
db.close()

