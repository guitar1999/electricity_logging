CREATE TABLE electricity_usage_dow (
    dow integer PRIMARY KEY CHECK (dow >= 0 AND dow <= 6),
    day_of_week text,
    kwh numeric,
    kwh_avg numeric,
    complete text CHECK (complete = 'yes' OR complete = 'no')
);
