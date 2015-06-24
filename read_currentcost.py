#!/usr/bin/python

# A script to read data from the CostCurrent EnviR
# Based on an example from Greg Fiske that was pulled from
# various sources on the web.
#
# Jesse Bishop
# 2013-03-14
#

print "read_currentcost.py starting up"

import ConfigParser, datetime, serial, sys, psycopg2
import xml.etree.ElementTree as ET 

loud = sys.argv[1]

# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read('/home/jessebishop/.pyconfig')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')

# A function to connect to the database
def dbcon(dbhost=dbhost, dbname=dbname, dbuser=dbuser, dbport=5432):
    db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
    return (db)

# Connect to the database
db = dbcon(dbhost, dbname, dbuser)

# Set the temperature adjustment factor
tempfactor = 2

# Establish a serial connection to the Current Cost
ser = serial.Serial(port='/dev/ttyUSB0',baudrate=57600)

# Define a function to get data from the current cost
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
    readtime = datetime.datetime.now().isoformat()
    outdict = {"temp" : temp, "watts1" : watts1, "watts2" : watts2, "watts3" : watts3, "time" : time, "readtime" : readtime}
    return outdict

# Create an empty list to hold the data if necessary
datalist = []

# Loop infinetly, read the current cost (this is the time constraint), and do stuff with the data    
while True:
    # Always get the data if you can!
    datalist.append(pullFromCurrentCost())
    if db.closed == 0:
        cursor = db.cursor()
        # Get the database time to see if the database is still up
        try:
            query = """SELECT CURRENT_TIMESTAMP;"""
            cursor.execute(query)
            db_timestamp = cursor.fetchall()
            db.commit()
        except psycopg2.OperationalError: # If not, add data to the datalist
            print "The db connection failed at time inquiry."
        else:
            while datalist:
                data = datalist.pop(0)
                try:
                    temp = (float(data['temp']) + tempfactor - 32) * 5 / 9
                    sql4 = """INSERT INTO temperature_test (temperature, device_id) VALUES ({0}, 'current_cost');""".format(temp)
                    cursor.execute(sql4)
                    db.commit()
                except Exception, msg:
                    print msg
                try:
                    totalwatts = int(data['watts1']) + int(data['watts2'])
                    watts_ch1 = int(data['watts1'])
                    watts_ch2 = int(data['watts2'])
                    watts_ch3 = int(data['watts3'])
                    readtime = data['readtime']
                    time = data['time']
                    sql = """INSERT INTO electricity_measurements (watts_ch1, watts_ch2, watts_ch3, measurement_time, device_time) VALUES ({0}, {1}, {2}, '{3}', '{4}');""".format(watts_ch1, watts_ch2, watts_ch3, readtime, time)
                    cursor.execute(sql)
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
        finally:
            cursor.close()
    else:
        print "The db connection has failed. Trying to reconnect..."
        db.close()
        dbcon(dbhost, dbname, dbuser)

# Close the db connection if True ever becomes False! Also, be worried.
db.close()
