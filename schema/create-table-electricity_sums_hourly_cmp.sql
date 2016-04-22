CREATE TABLE electricity_statistics.electricity_sums_hourly_cmp (
    start_date TIMESTAMP WITH TIME ZONE NOT NULL PRIMARY KEY,
    end_date TIMESTAMP WITH TIME ZONE,
    kwh NUMERIC NOT NULL
);
