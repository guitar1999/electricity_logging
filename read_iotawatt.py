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
parser.add_argument('-s', '--start', dest='start', required=True, default='m-1m', help='''The start time to get data from iotawatt.''')
parser.add_argument('-e', '--end', dest='end', required=True, default='m', help='''The start time to get data from iotawatt.''')
args = parser.parse_args()

# Get the data
try:
    r = requests.get('http://{0}/query?{1}'.format(iwhost, iwquery.format(args.start, args.end)))
    data = r.json()
    print(r.status_code)
    print(r.headers['content-type'])
except Exception as msg:
    print(msg)
    sys.exit(1)

# Stick the data into the celery queue to be loaded to postgres
for rec in data['data']:
    try:
        insert_iotawatt_electric.apply_async(args=rec, queue='electric')
    except Exception as msg:
        print(msg)
        print(rec)

