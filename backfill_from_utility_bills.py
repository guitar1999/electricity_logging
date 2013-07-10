#!/usr/bin/python

import datetime, psycopg2

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()

wfdb = psycopg2.connect(host='web309.webfaction.com', database='jessebishop_pg2', user='jessebishop_pg2')
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
            print dt
            #query = """INSERT INTO electricity_historical_utility_measurements (measurement_time, device_time, watts, tdiff) VALUES ('%s', '%s', %s, %s);""" % (mt, devtime, watts, tdiff)
            query = """INSERT INTO electricity_measurements (measurement_time, device_time, watts_ch1, watts_ch2, tdiff) VALUES ('%s', '%s', %s, %s, %s);""" % (mt, devtime, watts, w2, tdiff)
            cursor.execute(query)

cursor.close()
db.commit()
db.close()




