CREATE TABLE energy_statistics.electricity_statistics_dow (
    dow integer PRIMARY KEY CHECK (dow >= 0 AND dow <= 6),
    count integer,
    kwh_avg numeric,
    timestamp timestamp with time zone
);
