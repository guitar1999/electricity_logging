CREATE TABLE electricity_statistics.electricity_statistics_hourly_dow_season (
    hour integer CHECK (hour >= 0 AND hour <= 23),
    dow integer CHECK (dow >= 0 AND dow <= 6),
    season text,
    count integer,
    kwh_avg numeric,
    updated timestamp with time zone
);
\copy electricity_statistics.electricity_statistics_hourly_dow_season (hour, dow, season) FROM hourly_dow_season_statistics.data
UPDATE electricity_statistics.electricity_statistics_hourly_dow_season SET (count, kwh_avg, updated) = (0, 0, CURRENT_TIMESTAMP);
