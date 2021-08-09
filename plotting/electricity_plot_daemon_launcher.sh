#!/bin/bash

while [ 1 ]
do 
    /usr/local/bin/R --vanilla --slave < /Users/jbishop/git/electricity_logging/plotting/electricity_plot_daemon_worker.R
    echo "Failed at $(date)"
done
