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
import time
opdate = datetime.datetime.now()
print(opdate)

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
success = False
tries = 0
while success != True:
    f = requests.get(url)#, headers=headers)
    tries += 1
    status_code = f.status_code
    if status_code != 200:
        time.sleep(60)
        continue
    json_string = f.text
    #print(json_string)
    parsed_json = json.loads(json_string)
    # This is dumb, but I keep getting a cached version of the data on the first call, so let's try again if we get the cached data
    updated_time = parsed_json['properties']['updated']
    print('updated_time: {0}'.format(updated_time))
    if opdate - datetime.datetime.strptime(updated_time.split('+')[0], '%Y-%m-%dT%H:%M:%S') > datetime.timedelta(1):
        time.sleep(60)
        continue
    success = True
    print('tries: {0}'.format(tries))

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
# Move today's forecast HDD into the long term weather archive until we get a more reliable way to get this data (starting 2023-11-03)
query = '''INSERT INTO weather_data.weather_daily_mean_data (weather_date, hdd) SELECT forecast_date, hdd FROM weather_data.weather_forecast WHERE forecast_date = CURRENT_DATE ON CONFLICT (weather_date) DO NOTHING;'''
cursor.execute(query)
db.commit()
cursor.close()
db.close()

