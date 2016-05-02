from celery import Celery
import ConfigParser, psycopg2

app = Celery('db_inserter', broker='amqp://energy:energy@localhost')

@app.task
def insert_electric(watts_ch1, watts_ch2, watts_ch3, readtime, time):
    success = False
    while not success:
        try:
            config = ConfigParser.RawConfigParser()
            config.read('/home/jessebishop/.pyconfig')
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
            config.read('/home/jessebishop/.pyconfig')
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
