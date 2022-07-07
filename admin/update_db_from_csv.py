#!/usr/bin/python

# A script to read data from the CostCurrent EnviR
# Based on an example from Greg Fiske that was pulled from
# various sources on the web.
#
# Jesse Bishop
# 2013-03-14
#

print "update_db_from_csv.py starting up"

import ConfigParser
import sys
import os
import psycopg2
import datetime
from dateutil import parser

loud = sys.argv[1]
infile = sys.argv[2]
#if sys.argv[3]:
#    conv = True
#    dateconv = sys.argv[3]
conv = False

# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read(os.environ.get('HOME') + '/.pyconfig')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')

# Connect to the database
db = psycopg2.connect(host=dbhost, database=dbname, user=dbuser)
cursor = db.cursor()


tempfactor = 2
timeoffset = datetime.timedelta(0, 18295, 574526)

f = open(infile, 'r')


#while True:
for line in f.readlines():
    if not conv:
        totalwatts, watts_ch1, watts_ch2, watts_ch3, time, current_time = line.replace('\n', '').split(',')
    else:
        totalwatts, watts_ch1, watts_ch2, watts_ch3, time = line.replace('\n', '').split(',')
        timed = parser.parse(dateconv + ' ' + time)
        current_time = (timed + timeoffset).strftime('%Y-%m-%d %H:%M:%S')
    watts_ch1 = int(watts_ch1)
    watts_ch2 = int(watts_ch2)
    watts_ch3 = int(watts_ch3)
    print watts_ch1, watts_ch2, watts_ch3, current_time
        
    try:
        sql = "INSERT INTO electricity_measurements (watts_ch1, watts_ch2, watts_ch3, measurement_time, device_time) VALUES (%i, %i, %i, '%s', '%s') RETURNING emid;" % (watts_ch1, watts_ch2, watts_ch3, current_time, time)
        #print sql
        cursor.execute(sql)
        tid = cursor.fetchone()[0]
        sql2 = """UPDATE electricity_measurements SET tdiff = (SELECT date_part FROM (SELECT date_part('epoch', measurement_time - LAG(measurement_time) OVER (ORDER BY measurement_time)) FROM electricity_measurements WHERE emid IN (%s,(SELECT MAX(emid) FROM electricity_measurements WHERE emid < %s))) AS temp1 WHERE NOT date_part IS NULL) WHERE emid = %s;""" % (tid, tid, tid)
        cursor.execute(sql2)
        sql3 = """UPDATE electricity_measurements SET tdiff_device_time = (SELECT date_part FROM (SELECT date_part('epoch', device_time - LAG(device_time) OVER (ORDER BY device_time)) FROM electricity_measurements WHERE emid IN (%s,(SELECT MAX(emid) FROM electricity_measurements WHERE emid < %s))) AS temp1 WHERE NOT date_part IS NULL) WHERE emid = %s;""" % (tid, tid, tid)
        cursor.execute(sql3)
        db.commit()
    except Exception, msg:
        print msg, "in main"
        break

cursor.close()
db.close()
