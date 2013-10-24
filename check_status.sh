#!/bin/bash

status=$(/usr/local/pgsql93/bin/psql -t -A -c "SELECT (CURRENT_TIMESTAMP - measurement_time) > interval '1 minute' FROM (SELECT measurement_time FROM electricity_measurements ORDER BY measurement_time DESC LIMIT 1) AS x;")
#echo $status
if [ "$status" == "t" ]; then
    #Do something
    echo
fi
