#!/bin/bash

# Use sunwait to get the sunrise and sunset time for tomorrow 
checkdate=$(date -d 'tomorrow' +'%Y-%m-%d')
sunrise=$(/usr/local/bin/sunwait -p -y $(date  -d 'tomorrow' +'%Y') -m $(date -d 'tomorrow' +'%m') -d $(date -d 'tomorrow' +'%d') 43.921510N 70.084008W | grep 'Sun rises' | awk -F ',' '{print $1}' | grep -o '[0-9]\{4\}')
sunset=$(/usr/local/bin/sunwait -p -y $(date  -d 'tomorrow' +'%Y') -m $(date -d 'tomorrow' +'%m') -d $(date -d 'tomorrow' +'%d') 43.921510N 70.084008W | grep 'Sun rises' | awk -F ',' '{print $2}' | grep -o '[0-9]\{4\}')

# Get database connection info and insert data
configfile=${HOME}/.pyconfig
dbhost=$(grep -A 4 pidb $configfile | grep DBHOST | awk -F ' = ' '{print $2}')
dbname=$(grep -A 4 pidb $configfile | grep DBNAME | awk -F ' = ' '{print $2}')
dbuser=$(grep -A 4 pidb $configfile | grep DBUSER | awk -F ' = ' '{print $2}')
dbport=$(grep -A 4 pidb $configfile | grep DBPORT | awk -F ' = ' '{print $2}')
psql -X -h $dbhost -p $dbport -d $dbname -U $dbuser -c "INSERT INTO weather_data.astronomy_data (date, sunrise, sunset) VALUES ('$checkdate', '$sunrise', '$sunset');"
