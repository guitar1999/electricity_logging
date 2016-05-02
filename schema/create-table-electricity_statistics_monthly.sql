CREATE TABLE electricity_statistics.electricity_statistics_monthly (
    month integer PRIMARY KEY CHECK (month >= 1 AND month <= 12),
    count integer,
    kwh_avg numeric,
    previous_year numeric,
    updated timestamp with time zone
);
INSERT INTO electricity_statistics.electricity_statistics_monthly SELECT generate_series(1,12), 0, 0, 0, CURRENT_TIMESTAMP;
