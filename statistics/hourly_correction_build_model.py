#!/bin/env python

from sklearn.ensemble import RandomForestRegressor
from sklearn.externals import joblib
from sklearn.metrics import r2_score
from sqlalchemy import create_engine
import ConfigParser
import pandas as pd
import psycopg2 as pg

##############
# Get config #
##############
config = ConfigParser.RawConfigParser()
config.read('{0}/.pyconfig'.format(os.environ.get('HOME')))
dbhost = config.get('pidb', 'DBHOST')
dbname = config.get('pidb', 'DBNAME')
dbuser = config.get('pidb', 'DBUSER')
dbport = config.get('pidb', 'DBPORT')

# Create SQLAlchemy Engine
engine = create_engine('postgres://{0}@{1}:{2}/{3}'.format(dbuser, dbhost, dbport, dbname))

# Query to get clean master dataset for training
query = '''WITH pi AS (SELECT measurement_time::DATE AS sum_date, DATE_PART('hour', measurement_time) AS hour, SUM(watts_ch1 * tdiff / 1000. / 60 / 60) AS kwh_ch1, SUM(watts_ch2 * tdiff / 1000. / 60 / 60) AS kwh_ch2, SUM(watts_ch3 * tdiff / 1000. / 60 / 60) AS kwh_ch3, MAX(tdiff) AS max_tdiff FROM electricity_measurements WHERE measurement_time >= '2016-04-22 00:00:00' GROUP BY measurement_time::DATE, DATE_PART('hour', measurement_time)) SELECT c.kwh, c.sum_date, c.hour, pi.kwh_ch1, pi.kwh_ch2, pi.kwh_ch3 FROM cmp_electricity_sums_hourly_view c INNER JOIN pi ON c.sum_date=pi.sum_date AND c.hour=pi.hour WHERE NOT pi.max_tdiff > 100 AND (NOT pi.kwh_ch1 > 10 OR pi.kwh_ch2 > 10);'''
# Get the data
df = pd.read_sql_query(query, engine)
# Get the predictor columns
features = df.columns[2:]

# Initialize Random Forest and predict
rf = RandomForestRegressor(n_estimators=500, n_jobs=-1)
rf.fit(df[features], df['kwh'])

# Dump the file for later use
joblib.dump(rf, '/usr/local/electricity_logging/statistics/hourly_correction_model.pkl')

# Get data to be predicted
query = '''SELECT sum_date, hour, kwh_ch1, kwh_ch2, kwh_ch3 FROM electricity_statistics.electricity_sums_hourly_modeling_view;'''
df2 = pd.read_sql_query(query, engine)
# Predict
prediction = rf.predict(df2[df2.columns[1:]])
dfout = pd.concat([df2.reset_index(drop=True), pd.DataFrame(prediction)], axis=1)

# Connect to DB
db = pg.connect('host={0} port={1} dbname={2} user={3}'.format(dbhost, dbport, dbname, dbuser))
cur = db.cursor()

# Insert into a temp table
for index, row in dfout.iterrows():
    sql = '''INSERT INTO temp_electricity_sums_hourly_modeled_python2 (sum_date, hour, kwh_modeled) VALUES ('{0}', {1}, {2});'''.format(row['sum_date'], row['hour'], row[0])
    cur.execute(sql)
    if index % 250 == 0:
        db.commit()
db.commit()
cur.close()
db.close()

