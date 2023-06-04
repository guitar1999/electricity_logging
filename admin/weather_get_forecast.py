#!/bin/env python

import ConfigParser
import datetime
import json
import os
import psycopg2
import urllib2


import os
import ConfigParser, datetime, json, psycopg2 #, urllib2
import requests
opdate = datetime.datetime.now()

# Get the api key from our config file
config = ConfigParser.RawConfigParser()
config.read(os.environ.get('HOME') + '/.pyconfig')

#apikey = config.get('wunderground', 'APIKEY')

dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')
dbport = config.get('pidb', 'DBPORT')

# Connect to the database
db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
cursor = db.cursor()

# Connect to wunderground and get historical_data
url = 'https://api.weather.gov/gridpoints/GYX/79,71/forecast'
#f = urllib2.urlopen(url)
#json_string = f.read()
headers = {"User Agent": "blackosprey.com info@blackosprey.com"}
f = requests.get(url, headers=headers)
json_string = f.text
parsed_json = json.loads(json_string)

query = "DELETE FROM weather_data.weather_forecast_data WHERE NOT start_time::DATE = CURRENT_DATE;"
cursor.execute(query)

for p in parsed_json['properties']['periods']:
    starttime = p['startTime']
    endtime = p['endTime']
    temperature = p['temperature']
    forecast = p['shortForecast']
    daytime = p['isDaytime']
    query = '''INSERT INTO weather_data.weather_forecast_data (start_time, end_time, temperature, daytime, forecast) VALUES ('{0}', '{1}', {2}, {3}, '{4}');'''.format(starttime, endtime, temperature, daytime, forecast)
    cursor.execute(query)
    db.commit()

# Temporarily delete and update until we can unwind the views dependent on "weather_forecast" and turn that into a view
query = '''DELETE FROM weather_data.weather_forecast; INSERT INTO weather_data.weather_forecast (SELECT forecast_date, CASE WHEN (max_temp + min_temp) / 2.0 < 65 THEN ROUND(65 - ((max_temp + min_temp) / 2.0), 0) ELSE 0 END AS hdd FROM (SELECT start_time::DATE AS forecast_date, MAX(temperature) FILTER (WHERE NOT daytime) AS min_temp, MAX(temperature) FILTER (WHERE daytime) AS max_temp FROM weather_data.weather_forecast_data WHERE end_time - start_time = interval '12 hours' GROUP BY start_time::DATE ORDER BY start_time::DATE ) AS x WHERE NOT max_temp IS NULL AND NOT min_temp IS NULL);'''
cursor.execute(query)
db.commit()
cursor.close()
db.close()

