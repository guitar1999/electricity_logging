CREATE TABLE electricity_statistics.electricity_statistics_hourly (
    hour integer PRIMARY KEY CHECK (hour >= 0 AND hour <= 23),
    count integer,
    kwh_avg numeric,
    updated timestamp with time zone
);
INSERT INTO electricity_statistics.electricity_statistics_hourly (hour, count, kwh_avg, updated) SELECT generate_series(0,23), 0, 0, CURRENT_TIMESTAMP;
