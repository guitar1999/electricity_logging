CREATE TABLE electricity_usage_doy (
    doy integer PRIMARY KEY CHECK (doy > 0 AND doy <= 366),
    kwh numeric,
    kwh_avg numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no')
);
