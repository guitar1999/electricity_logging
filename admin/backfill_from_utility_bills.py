#!/usr/bin/python

import ConfigParser
import datetime
import os
import psycopg2

# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read(os.environ.get('HOME') + '/.pyconfig')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')
wfdbhost = config.get('wfdb', 'DBHOST')
wfdbname = config.get('wfdb', 'DBNAME')
wfdbuser = config.get('wfdb', 'DBUSER')

# Connect to the database
db = psycopg2.connect(host=dbhost, database=dbname, user=dbuser)
cursor = db.cursor()

wfdb = psycopg2.connect(host=wfdbhost, database=wfdbname, user=wfdbuser)
wfcursor = wfdb.cursor()

wfquery = """SELECT start_date, end_date, kwh::float / (end_date - start_date) AS kwh_per_day FROM house_electricity ORDER BY start_date;"""
wfcursor.execute(wfquery)
wfdata = wfcursor.fetchall()

for wfd in wfdata:
    startd, endd, kwhpd = wfd
    days = (endd - startd).days
    for d in range(0,days+1):
        dt = startd + datetime.timedelta(d)
        devtime = datetime.time(23,59,59)
        mt = datetime.datetime.combine(dt, devtime)
        watts = kwhpd / 24.0 * 1000 #/ 60 / 60
        w2 = 0
        tdiff = 60 * 60 * 24
        if dt < datetime.date(2013,3,22):
            print(dt)
            #query = """INSERT INTO electricity_historical_utility_measurements (measurement_time, device_time, watts, tdiff) VALUES ('%s', '%s', %s, %s);""" % (mt, devtime, watts, tdiff)
            query = """INSERT INTO electricity_measurements (measurement_time, device_time, watts_ch1, watts_ch2, tdiff) VALUES ('%s', '%s', %s, %s, %s);""" % (mt, devtime, watts, w2, tdiff)
            cursor.execute(query)

cursor.close()
db.commit()
db.close()




