CREATE TABLE electricity_iotawatt_statistics.generator_sums_hourly (
    sum_date DATE, 
    hour INTEGER, 
    kwh NUMERIC,
    PRIMARY KEY (sum_date, hour)
);