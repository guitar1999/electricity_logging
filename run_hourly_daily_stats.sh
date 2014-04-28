#!/bin/bash

dt=$1
shour=$2
ehour=$3
rundaily=$4

for h in {$shour..$ehour}
do
    echo $h
    echo 'e'
    /home/jessebishop/scripts/electricity_logging/generate_summary_hourly.py -hour $h -date $dt
    echo 'g'
    /home/jessebishop/scripts/gas_logging/generate_summary_gas_hourly.py -hour $h -date $dt
done

if [ "$rundaily" == "yes" ]
then
    echo 'edow'
    /home/jessebishop/scripts/electricity_logging/generate_summary_dow.py -date $dt
    echo 'edoy'
    /home/jessebishop/scripts/electricity_logging/generate_summary_doy.py -date $dt
    echo 'gdow'
    /home/jessebishop/scripts/gas_logging/generate_summary_gas_dow.py -date $dt
    echo 'gdoy'
    /home/jessebishop/scripts/gas_logging/generate_summary_gas_doy.py -date $dt
fi

