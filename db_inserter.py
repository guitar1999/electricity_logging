from celery import Celery
import ConfigParser
import os
import psycopg2

app = Celery('db_inserter', broker='amqp://energy:energy@localhost')

@app.task
def insert_electric(watts_ch1, watts_ch2, watts_ch3, readtime, time):
    success = False
    while not success:
        try:
            config = ConfigParser.RawConfigParser()
            config.read(os.environ.get('HOME') + '/.pyconfig')
            dbhost = config.get('pidb', 'DBHOST')
            dbname = config.get('pidb', 'DBNAME')
            dbuser = config.get('pidb', 'DBUSER')
            dbport = config.get('pidb', 'DBPORT')
            db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
            cursor = db.cursor()
            query = """INSERT INTO electricity_measurements (watts_ch1, watts_ch2, watts_ch3, measurement_time, device_time) VALUES ({0}, {1}, {2}, '{3}', '{4}');""".format(watts_ch1, watts_ch2, watts_ch3, readtime, time)
            cursor.execute(query)
            db.commit()
            cursor.close()
            db.close()
        except Exception, msg:
            success = False
        else:
            success = True

@app.task
def insert_temperature(temperature, device):
    success = False
    while not success:
        try:
            config = ConfigParser.RawConfigParser()
            config.read(os.environ.get('HOME') + '/.pyconfig')
            dbhost = config.get('pidb', 'DBHOST')
            dbname = config.get('pidb', 'DBNAME')
            dbuser = config.get('pidb', 'DBUSER')
            dbport = config.get('pidb', 'DBPORT')
            db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
            cursor = db.cursor()
            query = """INSERT INTO temperature_test (temperature, device_id) VALUES ({0}, '{1}');""".format(temperature, device)
            cursor.execute(query)
            db.commit()
            cursor.close()
            db.close()
        except Exception, msg:
            success = False
        else:
            success = True

@app.task
def insert_iotawatt_electric(measurement_time, watts_main_1,watts_main_2,watts_boiler,watts_subpanel_1,watts_subpanel_2,watts_water_pump,watts_generator_1,watts_generator_2):
    success = False
    while not success:
        try:
            config = ConfigParser.RawConfigParser()
            config.read(os.environ.get('HOME') + '/.pyconfig')
            dbhost = config.get('pidb', 'DBHOST')
            dbname = config.get('pidb', 'DBNAME')
            dbuser = config.get('pidb', 'DBUSER')
            dbport = config.get('pidb', 'DBPORT')
            db = psycopg2.connect(host=dbhost, port=dbport, database=dbname, user=dbuser)
            cursor = db.cursor()
            query = "INSERT INTO electricity_iotawatt.electricity_measurements (measurement_time, watts_main_1,watts_main_2,watts_boiler,watts_subpanel_1,watts_subpanel_2,watts_water_pump,watts_generator_1,watts_generator_2) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s) ON CONFLICT (measurement_time) DO NOTHING"
            cursor.execute(query, (measurement_time, watts_main_1,watts_main_2,watts_boiler,watts_subpanel_1,watts_subpanel_2,watts_water_pump,watts_generator_1,watts_generator_2))
            db.commit()
            cursor.close()
            db.close()
        except Exception, msg:
            success = False
        else:
            success = True

