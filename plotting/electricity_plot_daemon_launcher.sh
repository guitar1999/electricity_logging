#!/bin/bash

while [ 1 ]
do 
    R --vanilla --slave < ${HOME}/git/electricity_logging/plotting/electricity_plot_daemon_worker.R
    echo "Failed at $(date)"
done
