#!/usr/bin/python

# A script to read data from the CostCurrent EnviR
# Based on an example from Greg Fiske that was pulled from
# various sources on the web.
#
# Jesse Bishop
# 2013-03-14
#

print("read_currentcost.py starting up")

import os
import ConfigParser, datetime, serial, sys, psycopg2, urllib2, socket
import xml.etree.ElementTree as ET 
from db_inserter import insert_electric, insert_temperature

loud = sys.argv[1]

# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read(os.environ.get('HOME') + '/.pyconfig')


# Set the temperature adjustment factor
tempfactor = 2

# Establish a serial connection to the Current Cost
ser = serial.Serial(port='/dev/ttyUSB0',baudrate=57600)

# Define a function to get data from the current cost
def pullFromCurrentCost():
    # Read XML from Current Cost.  Try again if nothing is returned.
    watts1 = None
    watts2 = None
    watts3 = None
    sensor = None
    while watts1 == None and watts2 == None:
        line2 = ser.readline()
        try:
            tree  = ET.XML(line2)
            time = tree.findtext("time")
            watts1  = tree.findtext("ch1/watts")
            watts2  = tree.findtext("ch2/watts")
            watts3  = tree.findtext("ch3/watts")
            temp = tree.findtext("tmprF")
        except Exception as inst: # Catch XML errors
            sys.stderr.write("XML error: " + str(inst) + "\n")
            line2 = None
    ser.flushInput()
    readtime = datetime.datetime.now().isoformat()
    outdict = {"temp" : temp, "watts1" : watts1, "watts2" : watts2, "watts3" : watts3, "time" : time, "readtime" : readtime}
    return outdict


# Loop infinitly, read the current cost (this is the time constraint), and do stuff with the data    
while True:
    # Always get the data if you can!
    data = pullFromCurrentCost()
    print(data)
    try:
        temp = (float(data['temp']) + tempfactor - 32) * 5 / 9
        insert_temperature.apply_async(args=[temp, 'current_cost'], queue='electric')
    except Exception as msg:
        print(msg)
    try:
        if data['watts1'] != None:
            watts_ch1 = int(data['watts1'])
        else:
            watts_ch1 = 0
        if data['watts2'] != None:
            watts_ch2 = int(data['watts2'])
        else:
            watts_ch2 = 0
        if data['watts3'] != None:
            watts_ch3 = int(data['watts3'])
        else:
            watts_ch3 = 0
        totalwatts = watts_ch1 + watts_ch2
        readtime = data['readtime']
        time = data['time']
        insert_electric.apply_async(args=[watts_ch1, watts_ch2, watts_ch3, readtime, time], queue='electric')
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
        except Exception as msg:
            print(msg, "in tw")
        if loud == 'yes':
            print(totalwatts, watts_ch1, watts_ch2, str(watts_ch3), temp, time)
    except Exception as msg:
        print(msg, "in main")
