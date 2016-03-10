CREATE TABLE electricity_statistics.electricity_statistics_hourly_dow (
    hour integer CHECK (hour >= 0 AND hour <= 23),
    dow integer CHECK (dow >= 0 AND dow <= 6),
    count integer,
    kwh_avg numeric,
    updated timestamp with time zone
);

\copy electricity_statistics.electricity_statistics_hourly_dow (hour, dow) FROM hourly_dow_statistics.data
UPDATE electricity_statistics.electricity_statistics_hourly_dow SET (count, kwh_avg, updated) = (0, 0, CURRENT_TIMESTAMP);
