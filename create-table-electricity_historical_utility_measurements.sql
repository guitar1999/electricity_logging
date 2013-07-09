BEGIN;
CREATE TABLE electricity_historical_utility_measurements (
    ehum serial NOT NULL PRIMARY KEY,
    watts numeric,
    measurement_time timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
    device_time time without time zone,
    tdiff numeric,
    tdiff_device_time numeric
);
CREATE INDEX historical_measurement_time_index ON electricity_historical_utility_measurements USING btree (measurement_time);
CREATE INDEX historical_device_time_index ON electricity_historical_utility_measurements USING btree (device_time);
COMMIT;
