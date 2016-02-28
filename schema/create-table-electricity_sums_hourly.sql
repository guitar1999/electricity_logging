CREATE TABLE electricity_statistics.electricity_sums_hourly (
    sum_date DATE NOT NULL,
    hour INTEGER NOT NULL,
    kwh NUMERIC NOT NULL,
    PRIMARY KEY (sum_date, hour)
);
