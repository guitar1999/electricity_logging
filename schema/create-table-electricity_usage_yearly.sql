CREATE TABLE electricity.electricity_usage_yearly (
    year integer PRIMARY KEY,
    kwh numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no'),
    updated timestamp with time zone
);
