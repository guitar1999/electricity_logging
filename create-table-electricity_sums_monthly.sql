CREATE TABLE energy_statistics.electricity_sums_monthly (
    year INTEGER NOT NULL,
    month INTEGER NOT NULL,
    kwh NUMERIC NOT NULL,
    PRIMARY KEY (year, month)
);
