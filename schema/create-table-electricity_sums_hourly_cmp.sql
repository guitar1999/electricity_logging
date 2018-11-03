CREATE TABLE electricity_statistics.cmp_electricity_sums_hourly (
    start_date TIMESTAMP WITH TIME ZONE NOT NULL PRIMARY KEY,
    end_date TIMESTAMP WITH TIME ZONE,
    kwh NUMERIC NOT NULL,
    estimated TEXT
);
