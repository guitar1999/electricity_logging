#!/bin/bash

/usr/local/pgsql94/bin/psql -h $DBHOST -p $DBPORT -U $DBUSER -d $DBNAME -f /home/jessebishop/scripts/electricity_logging/predicted_use.sql
