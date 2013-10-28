#!/usr/bin/python

# A script to read data from the CostCurrent EnviR
# Based on an example from Greg Fiske that was pulled from
# various sources on the web.
#
# Jesse Bishop
# 2013-03-14
#

print "read_currentcost.py starting up"

import serial,sys,psycopg2
import xml.etree.ElementTree as ET 

loud = sys.argv[1]

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()


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
    data = pullFromCurrentCost()
    try:
        temp = (float(data[0]) + tempfactor - 32) * 5 / 9
        sql4 = """INSERT INTO temperature_test (temperature, device_id) VALUES (%s, 'current_cost');""" % (temp)
        cursor.execute(sql4)
        db.commit()
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
        cursor.execute(sql)
        tid = cursor.fetchone()[0]
        sql2 = """UPDATE electricity_measurements SET tdiff = (SELECT date_part FROM (SELECT date_part('epoch', measurement_time - LAG(measurement_time) OVER (ORDER BY measurement_time)) FROM electricity_measurements WHERE emid IN (%s,(SELECT MAX(emid) FROM electricity_measurements WHERE emid < %s))) AS temp1 WHERE NOT date_part IS NULL) WHERE emid = %s;""" % (tid, tid, tid)
        cursor.execute(sql2)
        sql3 = """UPDATE electricity_measurements SET tdiff_device_time = (SELECT date_part FROM (SELECT date_part('epoch', device_time - LAG(device_time) OVER (ORDER BY device_time)) FROM electricity_measurements WHERE emid IN (%s,(SELECT MAX(emid) FROM electricity_measurements WHERE emid < %s))) AS temp1 WHERE NOT date_part IS NULL) WHERE emid = %s;""" % (tid, tid, tid)
        cursor.execute(sql3)
        try:
            tw = str(totalwatts)
            while len(tw) < 4:
                tw = '0%s' % (tw)
            o = open('/var/www/electricity/instant.csv', 'w')
            o.write('kwh,a,b,c,d\n%s,%s,%s,%s,%s\n' % (totalwatts, tw[0], tw[1], tw[2], tw[3]))
            o.close()
            p = open('/var/www/electricity/hvac.csv', 'w')
            p.write('kwh\n%i\n' % (watts_ch3))
            p.close()
        except Exception, msg:
            print msg, "in tw"
        if loud == 'yes':
            print totalwatts, watts_ch1, watts_ch2, str(watts_ch3), temp, time
    except Exception, msg:
        print msg, "in main"

cursor.close()
db.close()
