#!/usr/bin/python

import datetime, matplotlib, os, psycopg2
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
from matplotlib import dates

db = psycopg2.connect(host='localhost', database='jessebishop',user='jessebishop')
cursor = db.cursor()

#############################
# Create usage for last hour
#cursor.execute("""SELECT kwh, end_time FROM electricity_usage WHERE start_time > CURRENT_TIMESTAMP - interval '1 hour' ORDER BY end_time;""")
os.system("""/usr/local/pgsql/bin/psql -t -A -c "SELECT row_to_json(row((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000., measurement_time)) FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '1 hour';" > /var/www/electricity/last_hour.json""")

#######################################
# Create hourly plot for last 24 hours 
#minutes = datetime.datetime.now().minute + 23 * 60
#cursor.execute("""SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh, date_part('hour', measurement_time) AS hour, to_timestamp(min(date_part('year', measurement_time))::text || '/' || min(date_part('month', measurement_time))::text || '/' || min(date_part('day', measurement_time))::text || ' ' || date_part('hour', measurement_time)::text || ':00:00', 'YYYY/MM/DD HH24:MI:SS') AS date  FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '%s minutes' GROUP BY hour ORDER BY date;""" % minutes)

#data = cursor.fetchall()
#kwh, hour, datesort = zip(*data)
# http://matplotlib.org/examples/api/barchart_demo.html for plotting fix
#fig = plt.figure()
#ax = fig.add_subplot(111)
#numbar = np.arange(len(hour))
#barwidth = 0.35
#rects = ax.bar(numbar, kwh, barwidth, color='r')
#ax.set_ylabel('kwh')
#ax.set_title('Hourly Electricity Usage')
#ax.set_xticks(numbar+barwidth/2)
#ax.set_xticklabels([str(this).split('.')[0] for this in hour])
#plt.savefig('/var/www/electricity/hourly.png')

####################################
# Create daily plot for last 30 days
#now = datetime.datetime.now()
#then = datetime.datetime(now.year, now.month, now.day, 0, 0, 0) - datetime.timedelta(30)
#interval = (now - then).total_seconds()
#cursor.execute("""SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh, date_part('day', measurement_time) AS day, to_date(min(date_part('year', measurement_time))::text || '/' || min(date_part('month', measurement_time))::text || '/' || min(date_part('day', measurement_time))::text, 'YYYY/MM/DD') AS date  FROM electricity_measurements  WHERE measurement_time > CURRENT_TIMESTAMP - interval '%s seconds' GROUP BY day ORDER BY date;""" % interval)

#data = cursor.fetchall()
#kwh, day, datesort = zip(*data)
#fig = plt.figure()
#ax = fig.add_subplot(111)
#numbar = np.arange(len(day))
#barwidth = 0.35
#rects = ax.bar(numbar, kwh, barwidth, color='r')
#ax.set_ylabel('kwh')
#ax.set_title('Daily Electricity Usage')
#ax.set_xticks(numbar+barwidth/2)
#ax.set_xticklabels([str(this).split('.')[0] for this in day])
#plt.savefig('/var/www/electricity/daily.png')

########################################
# Create monthly plot for last 12 months
now = datetime.datetime.now()
then = datetime.datetime(now.year - 1, now.month + 1, 1, 0, 0, 0)
interval = (now - then).total_seconds()
cursor.execute("""SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh, date_part('month', measurement_time) AS month, to_date(min(date_part('year', measurement_time))::text || '/' || min(date_part('month', measurement_time))::text, 'YYYY/MM') AS date  FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '%s seconds' GROUP BY month ORDER BY date;""" % interval)

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
cursor.execute("""SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh, date_part('year', measurement_time) AS year, to_date(min(date_part('year', measurement_time))::text, 'YYYY') AS date  FROM electricity_measurements GROUP BY year ORDER BY date;""")
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

os.system("scp /var/www/electricity/* web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/")
