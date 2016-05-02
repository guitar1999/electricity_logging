CREATE TABLE electricity.electricity_usage_monthly (
    month integer PRIMARY KEY CHECK (month > 0 AND month <= 12),
    kwh numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    updated timestamp with time zone
);
INSERT INTO electricity.electricity_usage_monthly (month, kwh, complete, updated) SELECT generate_series(1,12), 0, 'no', CURRENT_TIMESTAMP;
