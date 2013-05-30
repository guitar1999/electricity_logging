#!/usr/bin/python

import datetime, psycopg2

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()

now = datetime.datetime.now()
opdate = now - datetime.timedelta(1)
doy = opdate.timetuple().tm_yday
# Check to see if the data are complete
query = """SELECT max(tdiff) < 300  FROM temp_electricity WHERE time >= '%s' AND time < '%s';""" % (opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'))
cursor.execute(query)
data = cursor.fetchall()
maxint = data[0][0]
if maxint:
    complete = 'yes'
else:
    complete = 'no'

query = """UPDATE electricity_usage_doy SET kwh = (SELECT SUM(watts * tdiff / 60 / 60 / 1000.) AS kwh FROM temp_electricity WHERE time >= '%s' AND time < '%s') WHERE doy = %s;""" % (opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'), doy)
cursor.execute(query)
query = """UPDATE electricity_usage_doy SET kwh_avg = (SELECT AVG(kwh) FROM (SELECT SUM(watts * tdiff / 60 / 60 / 1000.) AS kwh FROM temp_electricity WHERE date_part('doy', time) = %s GROUP BY date_part('year', time)) AS x) WHERE doy = %s;""" % (doy, doy)
cursor.execute(query)
query = """UPDATE electricity_usage_doy SET complete = '%s' WHERE doy = %s;""" % (complete, doy)
cursor.execute(query)
query = """UPDATE electricity_usage_doy SET timestamp = CURRENT_TIMESTAMP WHERE doy = %s;""" % (doy)
cursor.execute(query)
cursor.close()
db.commit()
db.close()

