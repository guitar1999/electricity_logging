CREATE TABLE energy_statistics.electricity_statistics_monthly (
    month integer PRIMARY KEY CHECK (month >= 1 AND month <= 12),
    count integer,
    kwh_avg numeric,
    timestamp timestamp with time zone
);
