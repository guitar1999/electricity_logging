#!/usr/bin/python

import argparse
import ConfigParser
import os
import requests
import sys
from db_inserter import insert_iotawatt_electric


# Get info from our config file
try:
    config = ConfigParser.RawConfigParser()
    config.read('{0}/.pyconfig'.format(os.environ.get('HOME')))
    dbhost = config.get('pidb', 'DBHOST')
    dbname = config.get('pidb', 'DBNAME')
    dbuser = config.get('pidb', 'DBUSER')
    dbport = config.get('pidb', 'DBPORT')
    iwhost = config.get('iotawatt', 'IWHOST')
    iwquery = config.get('iotawatt', 'IWQUERY')
except Exception as msg:
    print(msg)
    sys.exit(1)

parser = argparse.ArgumentParser(prog='generate_summary.py', description='Summarize Electricity Usage')
parser.add_argument('-s', '--start', dest='start', default='m-1m', help='''The start time to get data from iotawatt.''')
parser.add_argument('-e', '--end', dest='end', default='m', help='''The start time to get data from iotawatt.''')
args = parser.parse_args()

# Get the data
try:
    r = requests.get('http://{0}/query?{1}'.format(iwhost, iwquery.format(args.start, args.end)))
    data = r.json()
#    print(r.status_code)
#    print(r.headers['content-type'])
except Exception as msg:
    print(msg)
    sys.exit(1)

# Stick the data into the celery queue to be loaded to postgres
for rec in data['data']:
    try:
        time, main_1, main_2, boiler, sbpanel_1, sbpanel_2, water_pmp, generator_1, generator_2 = rec
        if main_1 + main_2 >= generator_1 + generator_2:
            generator_1 = 0.0
            generator_2 = 0.0
        elif main_1 + main_2 < generator_1 + generator_2:
            main_1 = 0.0
            main_2 = 0.0
        new_rec = [time, main_1, main_2, boiler, sbpanel_1, sbpanel_2, water_pmp, generator_1, generator_2]
    except Exception as msg:
        print(msg)
        print(rec)
    try:
        insert_iotawatt_electric.apply_async(args=new_rec, queue='electric')
    except Exception as msg:
        print(msg)
        print(rec)