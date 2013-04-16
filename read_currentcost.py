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


tempfactor = 2

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
	try:
		totalwatts = int(data[1]) + int(data[2])
		watts_ch1 = int(data[1])
		watts_ch2 = int(data[2])
		temp = float(data[0]) + tempfactor
		time = data[3]
		sql = "INSERT INTO temp_electricity (watts, ch1_watts, ch2_watts, time, read_time) VALUES (%i, %i, %i, CURRENT_TIMESTAMP, '%s') RETURNING id;" % (totalwatts, watts_ch1, watts_ch2, time)
		cursor.execute(sql)
		tid = cursor.fetchone()[0]
		sql2 = """UPDATE temp_electricity SET tdiff = (SELECT date_part FROM (SELECT date_part('epoch', time - LAG(time) OVER (ORDER BY time)) FROM temp_electricity WHERE id IN (%s,%s)) AS temp1 WHERE NOT date_part IS NULL) WHERE id = %s;""" % (tid, tid - 1, tid)
		cursor.execute(sql2)
		sql3 = """UPDATE temp_electricity SET diff_cc = (SELECT date_part FROM (SELECT date_part('epoch', read_time - LAG(read_time) OVER (ORDER BY read_time)) FROM temp_electricity WHERE id IN (%s,%s)) AS temp1 WHERE NOT date_part IS NULL) WHERE id = %s;""" % (tid, tid - 1, tid)
		cursor.execute(sql3)
		db.commit()
		print totalwatts, watts_ch1, watts_ch2, temp, time
	except Exception, msg:
		print msg

cursor.close()
db.close()
