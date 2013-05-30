#!/usr/bin/python

import datetime, matplotlib, os, psycopg2
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import dates

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()

now = datetime.datetime.now()

#######################################
# Create hourly plot for last 24 hours
# Get the data from the round robin table first
ophour = now.hour - 1
cursor.execute("""SELECT hour, kwh, kwh_avg, kwh_avg_dow, complete FROM electricity_usage_hourly ORDER BY timestamp;""")
data = cursor.fetchall()
hour, kwh, kwh_avg, kwh_avg_dow, complete  = zip(*data)
splitpos = hour.index(ophour)

minutes = datetime.datetime.now().minute + 23 * 60
cursor.execute("""SELECT SUM(watts * tdiff / 60 / 60 / 1000.) AS kwh, date_part('hour', time) AS hour, to_timestamp(min(date_part('year', time))::text || '/' || min(date_part('month', time))::text || '/' || min(date_part('day', time))::text || ' ' || date_part('hour', time)::text || ':00:00', 'YYYY/MM/DD HH24:MI:SS') AS date  FROM temp_electricity WHERE time > CURRENT_TIMESTAMP - interval '%s minutes' GROUP BY hour ORDER BY date;""" % minutes)

data = cursor.fetchall()
kwh, hour, datesort = zip(*data)
# http://matplotlib.org/examples/api/barchart_demo.html for plotting fix
fig = plt.figure()
ax = fig.add_subplot(111)
numbar = np.arange(len(hour))
barwidth = 0.35
rects = ax.bar(numbar, kwh, barwidth, color='r')
ax.set_ylabel('kwh')
ax.set_title('Hourly Electricity Usage')
ax.set_xticks(numbar+barwidth/2)
ax.set_xticklabels([str(this).split('.')[0] for this in hour])
plt.savefig('/var/www/electricity/hourly.png')

