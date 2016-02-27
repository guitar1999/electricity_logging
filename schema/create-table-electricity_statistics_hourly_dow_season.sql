CREATE TABLE energy_statistics.electricity_statistics_hourly_dow_season (
    hour integer CHECK (hour >= 0 AND hour <= 23),
    dow integer CHECK (dow >= 0 AND dow <= 6),
    season text,
    count integer,
    kwh_avg_dow_season numeric,
    timestamp timestamp with time zone
);
