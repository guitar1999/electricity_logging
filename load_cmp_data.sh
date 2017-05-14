#!/bin/bash

infile=$1

csvcut -c 4,6 $infile | dbwf -c "\copy cmp_electricity_sums_hourly (start_date, kwh) from stdin with csv" && rm -rf $infile
