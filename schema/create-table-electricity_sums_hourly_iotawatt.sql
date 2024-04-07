CREATE TABLE electricity_iotawatt_statistics.electricity_sums_hourly (
    sum_date DATE, 
    hour INTEGER, 
    kwh NUMERIC,
    generator_usage BOOLEAN,
    PRIMARY KEY (sum_date, hour)
);