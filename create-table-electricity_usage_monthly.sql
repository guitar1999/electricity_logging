CREATE TABLE electricity_usage_monthly (
    month integer PRIMARY KEY CHECK (month > 0 AND month <= 12),
    kwh numeric,
    kwh_avg numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no')
);
