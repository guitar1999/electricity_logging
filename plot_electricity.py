#!/usr/bin/python

import matplotlib, psycopg2
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import dates

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()

#######################################
# Create hourly plot for last 24 hours 
cursor.execute("""SELECT SUM(kwh), date_part('hour', end_time) AS hour, to_timestamp(min(date_part('year', end_time))::text || '/' || min(date_part('month', end_time))::text || '/' || min(date_part('day', end_time))::text || ' ' || date_part('hour', end_time)::text || ':00:00', 'YYYY/MM/DD HH24:MI:SS') AS date  FROM electricity_usage  WHERE start_time > CURRENT_TIMESTAMP - interval '1 day' GROUP BY hour ORDER BY date;""")

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

####################################
# Create daily plot for last 30 days
cursor.execute("""SELECT SUM(kwh), date_part('day', end_time) AS day, to_date(min(date_part('year', end_time))::text || '/' || min(date_part('month', end_time))::text || '/' || min(date_part('day', end_time))::text, 'YYYY/MM/DD') AS date  FROM electricity_usage  WHERE start_time > CURRENT_TIMESTAMP - interval '30 days' GROUP BY day ORDER BY date;""")

data = cursor.fetchall()
kwh, day, datesort = zip(*data)
fig = plt.figure()
ax = fig.add_subplot(111)
numbar = np.arange(len(day))
barwidth = 0.35
rects = ax.bar(numbar, kwh, barwidth, color='r')
ax.set_ylabel('kwh')
ax.set_title('Daily Electricity Usage')
ax.set_xticks(numbar+barwidth/2)
ax.set_xticklabels([str(this).split('.')[0] for this in day])
plt.savefig('/var/www/electricity/daily.png')

########################################
# Create monthly plot for last 12 months

cursor.execute("""SELECT SUM(kwh), date_part('month', end_time) AS month, to_date(min(date_part('year', end_time))::text || '/' || min(date_part('month', end_time))::text, 'YYYY/MM') AS date  FROM electricity_usage WHERE start_time > CURRENT_TIMESTAMP - interval '1 year' GROUP BY month ORDER BY date;""")
data = cursor.fetchall()
kwh, month, datesort = zip(*data)
fig = plt.figure()
ax = fig.add_subplot(111)
numbar = np.arange(len(month))
barwidth = 0.35
rects = ax.bar(numbar, kwh, barwidth, color='r')
ax.set_ylabel('kwh')
ax.set_title('Monthly Electricity Usage')
ax.set_xticks(numbar+barwidth/2)
ax.set_xticklabels([str(this).split('.')[0] for this in month])
plt.savefig('/var/www/electricity/monthly.png')


############################
# Create yearly plot forever
cursor.execute("""SELECT SUM(kwh), date_part('year', end_time) AS year, to_date(min(date_part('year', end_time))::text, 'YYYY') AS date  FROM electricity_usage GROUP BY year ORDER BY date;""")
data = cursor.fetchall()
kwh, year, datesort = zip(*data)
fig = plt.figure()
ax = fig.add_subplot(111)
numbar = np.arange(len(year))
barwidth = 0.35
rects = ax.bar(numbar, kwh, barwidth, color='r')
ax.set_ylabel('kwh')
ax.set_title('Annual Electricity Usage')
ax.set_xticks(numbar+barwidth/2)
ax.set_xticklabels([str(this).split('.')[0] for this in year])
plt.savefig('/var/www/electricity/yearly.png')

cursor.close()
db.close()


