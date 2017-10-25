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
url = 'http://api.wunderground.com/api/{0}/forecast10day/q/USA/ME/BRUNSWICK.json'.format(apikey)
f = urllib2.urlopen(url)
json_string = f.read()
parsed_json = json.loads(json_string)

query = "TRUNCATE weather_data.weather_forecast;"
cursor.execute(query)

for fd in parsed_json['forecast']['simpleforecast']['forecastday']:
    # date
    fdd = fd['date']
    fdate = '''{0}-{1}-{2}'''.format(fdd['year'], fdd['month'], fdd['day'])
    high_temp = fd['high']['fahrenheit']
    low_temp = fd['low']['fahrenheit']
    avg_temp = (int(high_temp) + int(low_temp)) / 2.0
    if avg_temp < 65:
        hdd = round(65 - avg_temp, 0)
    else:
        hdd = 0
    query = """INSERT INTO weather_data.weather_forecast (forecast_date, hdd) VALUES ('{0}', {1});""".format(fdate, hdd)
    cursor.execute(query)
    db.commit()
cursor.close()
db.close()
