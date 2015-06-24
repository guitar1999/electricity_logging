#!/usr/bin/python

# A script to read data from the CostCurrent EnviR
# Based on an example from Greg Fiske that was pulled from
# various sources on the web.
#
# Jesse Bishop
# 2013-03-14
#

print "read_currentcost.py starting up"

import ConfigParser, serial, sys, psycopg2
import xml.etree.ElementTree as ET 

loud = sys.argv[1]

# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read('/home/jessebishop/.pyconfig')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')

# Connect to the database
db = psycopg2.connect(host=dbhost, database=dbname, user=dbuser)
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
        time = data[4]
        sql = "INSERT INTO electricity_measurements (watts_ch1, watts_ch2, watts_ch3, measurement_time, device_time) VALUES (%i, %i, %i, CURRENT_TIMESTAMP, '%s') RETURNING emid;" % (watts_ch1, watts_ch2, watts_ch3, time)
        cursor.execute(sql)
        tid = cursor.fetchone()[0]

        db.commit()
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
