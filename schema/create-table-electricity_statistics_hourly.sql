CREATE TABLE energy_statistics.electricity_statistics_hourly (
    hour integer PRIMARY KEY CHECK (hour >= 0 AND hour <= 23),
    count integer,
    kwh_avg numeric,
    timestamp timestamp with time zone
);
