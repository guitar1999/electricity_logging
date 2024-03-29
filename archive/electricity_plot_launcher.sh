#!/bin/bash

# Run this script as a cron job every minute. It should help cut down the load by running these sequentially when necessary

# See if it's already running
lockfile=/var/lock/electricity/plotting
if [ ! -d $(dirname lockfile) ]
then
    mkdir -p $(dirname lockfile)
fi
if [ -f $lockfile ]
then
    exit
else
    touch $lockfile
fi

minute=$(date +%M)

#These run every minute
/usr/bin/R --vanilla --slave < ${HOME}/scripts/electricity_logging/generate_plot_last_hour.R > /dev/null 2>&1 
#/usr/bin/R --vanilla --slave < ${HOME}/scripts/electricity_logging/generate_plot_last_24_hours.R > /dev/null 2>&1

if [ "$(echo "$minute % 5" | bc)" -eq "0" ]
then
    /usr/bin/R --vanilla --slave < ${HOME}/scripts/electricity_logging/generate_plot_hourly.R > /dev/null 2>&1
    /usr/bin/R --vanilla --slave < ${HOME}/scripts/electricity_logging/generate_plot_hourly_dow.R > /dev/null 2>&1
fi

if [ "$(echo "$minute % 20" | bc)" -eq "0" ]
then
    /usr/bin/R --vanilla --slave < ${HOME}/scripts/electricity_logging/generate_plot_daily.R > /dev/null 2>&1
fi

if [ "$(echo "$minute % 12" | bc)" -eq "0" ]
then
    /usr/bin/R --vanilla --slave < ${HOME}/scripts/electricity_logging/generate_plot_dow.R > /dev/null 2>&1
     /usr/bin/R --vanilla --slave < ${HOME}/scripts/temp_logging/generate_plot_away.R > /dev/null 2>&1
fi

if [ "$minute" -eq "53" ]
then
    /usr/bin/R --vanilla --slave < ${HOME}/scripts/electricity_logging/generate_plot_monthly.R > /dev/null 2>&1
fi

if [ "$minute" -eq "37" ]
then
    /usr/bin/R --vanilla --slave < ${HOME}/scripts/electricity_logging/generate_plot_yearly.R > /dev/null 2>&1
fi

rm -f $lockfile
