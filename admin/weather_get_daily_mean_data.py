#!/usr/local/bin/python2.7

import argparse
import ConfigParser
import datetime
import json
import os
import psycopg2
import urllib2

p = argparse.ArgumentParser(description='Downloads mean weather observations for yesterday and inserts them into the database')
p.add_argument('-d', '--date', dest='rundate', required=False, help='''Optionally provide a date for data download in the format 'YYYY-MM-DD'.''')
args = p.parse_args()

# Set the date
if args.rundate:
    opdate = datetime.datetime.strptime(args.rundate, '%Y-%m-%d')
else:
    opdate = datetime.datetime.now() - datetime.timedelta(1)

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

# Connect to wunderground and get historical_data
url = 'http://api.wunderground.com/api/{0}/history_{1}/q/USA/ME/BRUNSWICK.json'.format(apikey, opdate.strftime('%Y%m%d'))
f = urllib2.urlopen(url)
json_string = f.read()
parsed_json = json.loads(json_string)

# Get the data (more later?)
hdd = parsed_json['history']['dailysummary'][0]['heatingdegreedays'] or None
meandewpti = parsed_json['history']['dailysummary'][0]['meandewpti'] or None
meanpressurei = parsed_json['history']['dailysummary'][0]['meanpressurei'] or None
meantempi = parsed_json['history']['dailysummary'][0]['meantempi'] or None
meanvisi = parsed_json['history']['dailysummary'][0]['meanvisi'] or None
meanwdird = parsed_json['history']['dailysummary'][0]['meanwdird'] or None
meanwindspdi = parsed_json['history']['dailysummary'][0]['meanwindspdi'] or None

# Stick it in the database
query = """INSERT INTO weather_daily_mean_data (weather_date, hdd, mean_dewpoint, mean_pressure, mean_temperature, mean_visibility, mean_wind_direction, mean_wind_speed) VALUES (%s, %s, %s, %s, %s, %s, %s, %s);"""
cursor.execute(query, (opdate.date(), hdd, meandewpti ,meanpressurei ,meantempi ,meanvisi ,meanwdird ,meanwindspdi))
db.commit()
cursor.close()
db.close()

