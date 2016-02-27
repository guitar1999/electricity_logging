CREATE TABLE electricity_usage_yearly (
    year integer PRIMARY KEY,
    kwh numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    timestamp timestamp with time zone
);
