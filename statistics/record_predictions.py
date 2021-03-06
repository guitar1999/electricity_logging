#!/usr/bin/python

import ConfigParser, datetime, os, psycopg2

##############
# Get config #
##############
config = ConfigParser.RawConfigParser()
config.read('{0}/.pyconfig'.format(os.environ.get('HOME')))
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')
dbport = config.get('pidb', 'DBPORT')


###########################
# Connect to the database #
###########################
db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
cursor = db.cursor()

sql = '''INSERT INTO electricity_statistics.electricity_cumulative_predictions (prediction_rundate, predicted_timestamp, predicted_cumulative_kwh) SELECT CURRENT_TIMESTAMP, timestamp, cumulative_kwh FROM electricity_plotting.cumulative_predicted_use_this_month_view;'''
cursor.execute(sql)
db.commit()
cursor.close()
db.close()
