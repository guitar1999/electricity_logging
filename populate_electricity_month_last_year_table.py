#!/usr/bin/python

import argparse, ConfigParser, datetime, psycopg2, sys

p = argparse.ArgumentParser(prog="populate_electricity_month_last_year_table")
p.add_argument("-month", dest="runmonth", required=False, help="The month to put in the table.")
p.add_argument("-year", dest="runyear", required=False, help="The year to put in the table.")
args = p.parse_args()

# Get the db config from our config file
config = ConfigParser.RawConfigParser()
config.read('/home/jessebishop/.pyconfig')
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')

# Connect to the database
db = psycopg2.connect(host=dbhost, database=dbname, user=dbuser)
cursor = db.cursor()

# Set the date
if args.runmonth and args.runyear:
    month = args.runmonth
    year = args.runyear
elif (args.runmonth and not args.runyear) or (args.runyear and not args.runmonth):
    print "You need to provide both month and year!"
    sys.exit(1)
else:
    now = datetime.datetime.now()
    month = now.month
    year = now.year - 1

print month, year