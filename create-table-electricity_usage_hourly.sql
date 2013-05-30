CREATE TABLE electricity_usage_hourly (
    hour integer PRIMARY KEY CHECK (hour >= 0 AND hour <= 23),
    kwh numeric,
    kwh_avg numeric,
    kwh_avg_dow numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no')
);
