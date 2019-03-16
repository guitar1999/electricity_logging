#!/usr/local/bin/python2.7

import ConfigParser, datetime, json, psycopg2, urllib2

opdate = datetime.datetime.now()

# Get the api key from our config file
config = ConfigParser.RawConfigParser()
config.read('/home/jessebishop/.pyconfig')
apikey = config.get('wunderground', 'APIKEY')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')
dbport = config.get('pidb', 'DBPORT')

# Connect to the database
db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
cursor = db.cursor()

# Connect to wunderground and get historical_data
url = 'https://api.weather.gov/gridpoints/GYX/79,71/forecast'
f = urllib2.urlopen(url)
json_string = f.read()
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
cursor.close()
db.close()

