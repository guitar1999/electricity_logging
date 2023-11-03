#!/usr/bin/python

import argparse
import ConfigParser
import datetime
import json
import os
import psycopg2
import requests
from tweet import tweet

# Allow the script to be run on a specific day of the week
p = argparse.ArgumentParser(prog="generate_summary_boiler_daily.py")
p.add_argument('-date', dest="rundate", required=False, help="The date to run in format 'YYYY-MM-DD'.")
args = p.parse_args()

# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read(os.environ.get('HOME') + '/.pyconfig')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')
dbport = config.get('pidb', 'DBPORT')
slackhook = config.get('slack', 'WEBHOOK_URL')

# Connect to the database
db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
cursor = db.cursor()

# Set rundate
if args.rundate:
    opdate = datetime.datetime.strptime(args.rundate, '%Y-%m-%d')
    now = opdate + datetime.timedelta(1)
else:
    now = datetime.datetime.now()
    opdate = now - datetime.timedelta(1)

query = """SELECT ROUND(gallons, 2) AS gallons, ROUND(kwh, 2) AS kwh, cycles, ROUND(total_runtime, 2) AS total_runtime, ROUND(avg_runtime, 2) AS avg_runtime, ROUND(min_runtime, 2) AS min_runtime, ROUND(max_runtime, 2) AS max_runtime FROM water_summary('{0} 00:00:00', '{0} 23:59:59')""".format(opdate.strftime('%Y-%m-%d'))
cursor.execute(query)
data = cursor.fetchall()
gallons, kwh, cycles, total_runtime, avg_runtime, min_runtime, max_runtime = data[0]
query = """
SELECT 
    ms.season, 
    TO_CHAR('{0}'::DATE, 'Day') AS day, 
    gallons_avg AS gallons_avg 
FROM 
    water_statistics.water_statistics_dow_view ws 
    INNER JOIN weather_data.meteorological_season ms 
        ON ws.season = ms.season
    WHERE 
        ws.dow = DATE_PART('DOW', '{0}'::DATE) 
        AND ms.doy = DATE_PART('DOY', '{0}'::DATE);
""".format(opdate.strftime('%Y-%m-%d'))
cursor.execute(query)
data = cursor.fetchall()
season, day, gallons_avg = data[0]

qualifier = 'more' if gallons > gallons_avg else 'less'

status = """Extracted {0} gallons of water. That's {4} than average for a {5} in the {6}. Water Pump: {1} cycles, mean of {2} min/cycle using {3} kwh. """.format(round(gallons, 1), cycles, round(avg_runtime, 1), round(kwh, 1), qualifier, day.strip(), season)
if not args.rundate:
    tweet(status)
    headers = {'Content-type': 'application/json'}
    payload = {'text': '{0}'.format(status), 'link_names': 1}
    r = requests.post(slackhook, headers=headers, data=json.dumps(payload))
else:
    print(status)

# Close database connection
cursor.close()
db.close()
