from celery import Celery
import psycopg2

app = Celery('db_inserter', broker='amqp://localhost')

@app.task
def into_db(x):
    success = False
    while not success:
        try:
            db = psycopg2.connect(host='localhost', database='jbishop', user='jbishop')
            cursor = db.cursor()
            query = "INSERT INTO celery_test (id, ts) VALUES ({0}, CURRENT_TIMESTAMP);".format(x)
            cursor.execute(query)
            db.commit()
            cursor.close()
            db.close()
        except Exception, msg:
            success = False
        else:
            success = True

