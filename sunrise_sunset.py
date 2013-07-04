#!/usr/bin/python

import datetime, json, psycopg2, urllib2

# Connect to wunderground and get sunrise and sunset times
apikey = 'ee7f65f21cceab3a'
url = 'http://api.wunderground.com/api/{0}/astronomy/q/USA/MA/East_Falmouth.json'.format(apikey)
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
db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()
query = """INSERT INTO astronomy_data (date, sunrise, sunset) VALUES ('{0}', '{1}', '{2}');""".format(now.date(), sunrise.time(), sunset.time())
cursor.execute(query)
db.commit()
cursor.close()
db.close()

