#!/usr/bin/python

import datetime, psycopg2

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()

month = datetime.datetime.now().month - 1
year = datetime.datetime.now().year
if month == 12:
    year = year - 1

query = """SELECT date_part('day', min(time)) = 1, date_part('day', max(time)) = num_days(%s,%s), max(tdiff) < 300  FROM temp_electricity WHERE date_part('month', time) = %s AND date_part('year', time) = %s;""" % (year, month, month, year)
cursor.execute(query)
data = cursor.fetchall()
mmin, mmax, maxint = zip(*data)
if mmin[0] and mmax[0] and maxint[0]:
    complete = 'yes'
else:
    complete = 'no'

query = """UPDATE electricity_usage_monthly SET kwh = (SELECT SUM(watts * tdiff / 60 / 60 / 1000.) AS kwh FROM temp_electricity WHERE date_part('month', time) = %s AND date_part('year', time) = %s) WHERE month = %s;""" % (month, year, month)
cursor.execute(query)
query = """UPDATE electricity_usage_monthly SET kwh_avg = (SELECT AVG(kwh) FROM (SELECT SUM(watts * tdiff / 60 / 60 / 1000.) AS kwh FROM temp_electricity WHERE date_part('month', time) = %s GROUP BY date_part('year', time)) AS x) WHERE month = %s;""" % (month, month)
cursor.execute(query)
query = """UPDATE electricity_usage_monthly SET complete = '%s' WHERE month = %s;""" % (complete, month)
cursor.execute(query)
query = """UPDATE electricity_usage_monthly SET timestamp = CURRENT_TIMESTAMP WHERE month = %s;""" % (month)
cursor.execute(query)
cursor.close()
db.commit()
db.close()

