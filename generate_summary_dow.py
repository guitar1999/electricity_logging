#!/usr/bin/python

import datetime, psycopg2

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()

now = datetime.datetime.now()
opdate = now - datetime.timedelta(1)
dow = opdate.isoweekday()
# Make sunday 0 to match postgres style rather than python style
if dow == 7:
    dow = 0
# Check to see if the data are complete
query = """SELECT max(tdiff) < 300  FROM temp_electricity WHERE time >= '%s' AND time < '%s';""" % (opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'))
cursor.execute(query)
data = cursor.fetchall()
maxint = data[0][0]
if maxint:
    complete = 'yes'
else:
    complete = 'no'

query = """UPDATE electricity_usage_dow SET kwh = (SELECT SUM(watts * tdiff / 60 / 60 / 1000.) AS kwh FROM temp_electricity WHERE time >= '%s' AND time < '%s') WHERE dow = %s;""" % (opdate.strftime('%Y-%m-%d'), now.strftime('%Y-%m-%d'), dow)
cursor.execute(query)
query = """UPDATE electricity_usage_dow SET kwh_avg = (SELECT AVG(kwh) FROM (SELECT SUM(watts * tdiff / 60 / 60 / 1000.) AS kwh FROM temp_electricity WHERE date_part('dow', time) = %s GROUP BY date_part('year', time), date_part('doy', time)) AS x) WHERE dow = %s;""" % (dow, dow)
cursor.execute(query)
query = """UPDATE electricity_usage_dow SET complete = '%s' WHERE dow = %s;""" % (complete, dow)
cursor.execute(query)
query = """UPDATE electricity_usage_dow SET timestamp = CURRENT_TIMESTAMP WHERE dow = %s;""" % (dow)
cursor.execute(query)
cursor.close()
db.commit()
db.close()

