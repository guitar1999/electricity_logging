#!/usr/local/bin/python2.7

import ConfigParser
import datetime
import json
import os
import psycopg2
import urllib2

# Get the api key from our config file
config = ConfigParser.RawConfigParser()
config.read(os.environ.get('HOME') + '/.pyconfig')
apikey = config.get('wunderground', 'APIKEY')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')
dbport = config.get('pidb', 'DBPORT')

# Connect to the database
db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
cursor = db.cursor()

# Connect to wunderground and get sunrise and sunset times
url = 'http://api.wunderground.com/api/{0}/astronomy/q/USA/ME/Brunswick.json'.format(apikey)
f = urllib2.urlopen(url)
json_string = f.read()
parsed_json = json.loads(json_string)
sunrise_json = parsed_json['sun_phase']['sunrise']
sunset_json = parsed_json['sun_phase']['sunset']

# Construct the datetime objects
now = datetime.datetime.now()
sunrise = datetime.datetime(now.year, now.month, now.day, int(sunrise_json['hour']), int(sunrise_json['minute']), 0)
sunset = datetime.datetime(now.year, now.month, now.day, int(sunset_json['hour']), int(sunset_json['minute']), 0)

# Stick it in the database
query = """INSERT INTO astronomy_data (date, sunrise, sunset) VALUES ('{0}', '{1}', '{2}');""".format(now.date(), sunrise.time(), sunset.time())
cursor.execute(query)
db.commit()
cursor.close()
db.close()

