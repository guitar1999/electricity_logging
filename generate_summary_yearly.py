#!/usr/bin/python

import datetime, psycopg2

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()

year = datetime.datetime.now().year - 1
if month == 12:
    year = year - 1

query = """SELECT min(measurement_time)::date = '%s-01-01'::date, max(measurement_time)::date = '%s-12-31'::date, max(tdiff) < 300  FROM electricity_measurements WHERE date_part('year', measurement_time) = %s;""" % (year, year, year)
cursor.execute(query)
data = cursor.fetchall()
mmin, mmax, maxint = zip(*data)
if mmin[0] and mmax[0] and maxint[0]:
    complete = 'yes'
else:
    complete = 'no'

query = """INSERT INTO electricity_usage_yearly (year, kwh, complete, timestamp) VALUES (%s, (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE date_part('year', measurement_time) = %s), '%s', CURRENT_TIMESTAMP);""" % (year, year, complete)
cursor.execute(query)
cursor.close()
db.commit()
db.close()
