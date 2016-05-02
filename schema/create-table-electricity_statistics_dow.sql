CREATE TABLE electricity_statistics.electricity_statistics_dow (
    dow integer PRIMARY KEY CHECK (dow >= 0 AND dow <= 6),
    count integer,
    kwh_avg numeric,
    updated timestamp with time zone
);
INSERT INTO electricity_statistics.electricity_statistics_dow (dow, count, kwh_avg, updated) SELECT generate_series(0,6), 0, 0, CURRENT_TIMESTAMP;
