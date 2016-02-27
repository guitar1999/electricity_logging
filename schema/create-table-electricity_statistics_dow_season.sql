CREATE TABLE energy_statistics.electricity_statistics_dow_season (
    dow integer CHECK (dow >= 0 AND dow <= 6),
    season text,
    count integer,
    kwh_avg numeric,
    timestamp timestamp with time zone
);
