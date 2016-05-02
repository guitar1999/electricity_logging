#!/usr/bin/python

# A script to read data from the CostCurrent EnviR
# Based on an example from Greg Fiske that was pulled from
# various sources on the web.
#
# Jesse Bishop
# 2013-03-14
#

print "read_currentcost.py starting up"

import ConfigParser, serial, sys#, psycopg2
import xml.etree.ElementTree as ET 
from datetime import datetime
loud = sys.argv[1]

# Connect to the database
t = open('/home/jessebishop/temps12.csv', 'w')
e = open('/home/jessebishop/elec12.csv', 'w')
s = open('/home/jessebishop/dbinserts12.sql', 'w')

tempfactor = 2

ser = serial.Serial(port='/dev/ttyUSB0',baudrate=57600)

def pullFromCurrentCost():
    # Read XML from Current Cost.  Try again if nothing is returned.
    watts1  = None
    watts2 = None
    watts3 = None
    sensor = None
    while watts1 == None:
        line2 = ser.readline()
        try:
            tree  = ET.XML(line2)
            time = tree.findtext("time")
            watts1  = tree.findtext("ch1/watts")
            watts2  = tree.findtext("ch2/watts")
            watts3  = tree.findtext("ch3/watts")
            temp = tree.findtext("tmprF")
        except Exception, inst: # Catch XML errors
            sys.stderr.write("XML error: " + str(inst) + "\n")
            line2 = None
    ser.flushInput()
    return temp, watts1, watts2, watts3, time
while True:
    n = datetime.datetime.now().utcnow().isoformat()
    data = pullFromCurrentCost()
    try:
        temp = (float(data[0]) + tempfactor - 32) * 5 / 9
        sql4 = """INSERT INTO temperature_test (temperature, device_id) VALUES (%s, 'current_cost');""" % (temp)
#        cursor.execute(sql4)
#        db.commit()
        t.write('{0},current_cost,{1}\n'.format(temp,n))
        t.flush()
    except Exception, msg:
        print msg
    try:
        totalwatts = int(data[1]) + int(data[2])
        watts_ch1 = int(data[1])
        watts_ch2 = int(data[2])
        watts_ch3 = int(data[3])
        #temp = (float(data[0]) + tempfactor - 32) * 5 / 9
        time = data[4]
        #sql4 = """INSERT INTO temperature_test (temperature, device_id) VALUES (%s, 'current_cost');""" % (temp)
        #cursor.execute(sql4)
        #db.commit()
        sql = "INSERT INTO electricity_measurements (watts_ch1, watts_ch2, watts_ch3, measurement_time, device_time) VALUES (%i, %i, %i, CURRENT_TIMESTAMP, '%s') RETURNING emid;" % (watts_ch1, watts_ch2, watts_ch3, time)
#        cursor.execute(sql)
#        tid = cursor.fetchone()[0]
        tid = -9999
        sql2 = """UPDATE electricity_measurements SET tdiff = (SELECT date_part FROM (SELECT date_part('epoch', measurement_time - LAG(measurement_time) OVER (ORDER BY measurement_time)) FROM electricity_measurements WHERE emid IN (%s,(SELECT MAX(emid) FROM electricity_measurements WHERE emid < %s))) AS temp1 WHERE NOT date_part IS NULL) WHERE emid = %s;""" % (tid, tid, tid)
#        cursor.execute(sql2)
        sql3 = """UPDATE electricity_measurements SET tdiff_device_time = (SELECT date_part FROM (SELECT date_part('epoch', device_time - LAG(device_time) OVER (ORDER BY device_time)) FROM electricity_measurements WHERE emid IN (%s,(SELECT MAX(emid) FROM electricity_measurements WHERE emid < %s))) AS temp1 WHERE NOT date_part IS NULL) WHERE emid = %s;""" % (tid, tid, tid)
#        cursor.execute(sql3)
        e.write('{0},{1},{2},{3},{4}\n'.format(watts_ch1,watts_ch2,watts_ch3,time,n))
        e.flush()
        s.write(sql + '\n')
        s.write(sql2 + '\n')
        s.write(sql3 + '\n')
        s.flush()
    except Exception, msg:
        print msg, "in main"

t.close()
e.close()
s.close()

#cursor.close()
#db.close()
