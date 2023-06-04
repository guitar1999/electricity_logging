CREATE TABLE electricity_iotawatt_statistics.electricity_minimums_hourly ( 
    sum_date DATE
    , hour INTEGER
    , watts NUMERIC
    , PRIMARY KEY (sum_date, hour)
);