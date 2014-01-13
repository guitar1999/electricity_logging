CREATE TABLE energy_statistics.electricity_statistics_hourly_season (
    hour integer CHECK (hour >= 0 AND hour <= 23),
    season text,
    count integer,
    kwh_avg_season numeric,
    timestamp timestamp with time zone
);
