CREATE TABLE energy_statistics.electricity_sums_hourly (
    date DATE NOT NULL,
    hour INTEGER NOT NULL,
    kwh NUMERIC NOT NULL,
    PRIMARY KEY (date, hour)
);
