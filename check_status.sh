#!/bin/bash

status=$(/usr/local/pgsql93/bin/psql -t -A -c "SELECT CURRENT_TIMESTAMP - MAX(measurement_time) > interval '5 minutes' FROM electricity_measurements;")
#echo $status
if [ "$status" == "t" ]; then
    #Do something
    echo
fi
