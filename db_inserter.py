from celery import Celery
import configparser
import os
import psycopg2

config = configparser.RawConfigParser()
config.read(os.environ.get('HOME') + '/.pyconfig')
rabbitmq_host = config.get('rabbitmq', 'RABBITMQ_HOST')
rabbitmq_user = config.get('rabbitmq', 'RABBITMQ_USER')
rabbitmq_pass = config.get('rabbitmq', 'RABBITMQ_PASS')

app = Celery('db_inserter', broker=f'amqp://{rabbitmq_user}:{rabbitmq_pass}@{rabbitmq_host}')

@app.task(name='Insert Iotawatt Electric')
def insert_iotawatt_electric(measurement_time, watts_main_1,watts_main_2,watts_boiler,watts_subpanel_1,watts_subpanel_2,watts_water_pump,watts_generator_1,watts_generator_2):
    success = False
    while not success:
        try:
            config = configparser.RawConfigParser()
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
        except Exception as msg:
            success = False
        else:
            success = True

