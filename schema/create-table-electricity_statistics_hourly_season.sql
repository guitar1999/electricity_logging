CREATE TABLE electricity_statistics.electricity_statistics_hourly_season (
    hour integer CHECK (hour >= 0 AND hour <= 23),
    season text,
    count integer,
    kwh_avg numeric,
    updated timestamp with time zone
);

INSERT INTO electricity_statistics.electricity_statistics_hourly_season (hour, season, count, kwh_avg, updated) SELECT generate_series(0,23), 'winter', 0, 0, CURRENT_TIMESTAMP;
INSERT INTO electricity_statistics.electricity_statistics_hourly_season (hour, season, count, kwh_avg, updated) SELECT generate_series(0,23), 'spring', 0, 0, CURRENT_TIMESTAMP;
INSERT INTO electricity_statistics.electricity_statistics_hourly_season (hour, season, count, kwh_avg, updated) SELECT generate_series(0,23), 'summer', 0, 0, CURRENT_TIMESTAMP;
INSERT INTO electricity_statistics.electricity_statistics_hourly_season (hour, season, count, kwh_avg, updated) SELECT generate_series(0,23), 'fall', 0, 0, CURRENT_TIMESTAMP;

