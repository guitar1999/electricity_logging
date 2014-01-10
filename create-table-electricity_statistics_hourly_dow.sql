CREATE TABLE energy_statistics.electricity_statistics_hourly_dow (
    hour integer CHECK (hour >= 0 AND hour <= 23),
    dow integer CHECK (dow >= 0 AND dow <= 6),
    count integer,
    kwh_avg_dow numeric,
    timestamp timestamp with time zone
);
