#!/bin/bash

while [ 1 ]
do 
    /usr/bin/R --vanilla --slave < /usr/local/electricity_logging/electricity_plot_daemon_worker.R
    echo "Failed at $(date)"
done
