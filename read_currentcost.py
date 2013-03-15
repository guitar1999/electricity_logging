#!/usr/bin/python

# A script to read data from the CostCurrent EnviR
# Based on an example from Greg Fiske that was pulled from
# various sources on the web.d
#
# Jesse Bishop
# 2013-03-14
#

import serial,sys,psycopg2
import xml.etree.ElementTree as ET 

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()


tempfactor = 0

ser = serial.Serial(port='/dev/ttyUSB0',baudrate=57600)

def pullFromCurrentCost():
    # Read XML from Current Cost.  Try again if nothing is returned.
    watts1  = None
    watts2 = None
    sensor = None
    while watts1 == None:
        line2 = ser.readline()
        try:
            tree  = ET.XML(line2)
            time = tree.findtext("time")
            watts1  = tree.findtext("ch1/watts")
            watts2  = tree.findtext("ch2/watts")
            temp = tree.findtext("tmprF")
        except Exception, inst: # Catch XML errors
            sys.stderr.write("XML error: " + str(inst) + "\n")
            line2 = None
    ser.flushInput()
    return temp, watts1, watts2, time
while True:
	data = pullFromCurrentCost()
	totalwatts = int(data[1]) + int(data[2])
	temp = float(data[0]) + tempfactor
	time = data[3]
	sql = "INSERT INTO temp_electricity (watts, time, read_time) VALUES (%i, CURRENT_TIMESTAMP, '%s');" % (totalwatts, time)
	cursor.execute(sql)
	db.commit()
	print totalwatts, temp, time

cursor.close()
db.close()
