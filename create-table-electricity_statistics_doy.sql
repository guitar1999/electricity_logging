CREATE TABLE energy_statistics.electricity_statistics_doy (
    doy integer PRIMARY KEY CHECK (doy >= 1 AND doy <= 366),
    count integer,
    kwh_avg numeric,
    timestamp timestamp with time zone
);
