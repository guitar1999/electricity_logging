CREATE TABLE energy_statistics.electricity_statistics_month (
    monthly integer PRIMARY KEY CHECK (monthly >= 1 AND monthly <= 12),
    count integer,
    kwh_avg numeric,
    timestamp timestamp with time zone
);
