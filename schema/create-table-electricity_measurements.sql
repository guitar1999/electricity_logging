CREATE TABLE electricity.electricity_measurements (
	emid serial NOT NULL PRIMARY KEY,
	watts_ch1 integer NOT NULL,
	watts_ch2 integer NOT NULL,
	watts_ch3 integer,
	measurement_time timestamp with time zone NOT NULL DEFAULT CURRENT_TIMESTAMP,
	device_time time without time zone,
	tdiff numeric,
    tdiff_device_time numeric
);
CREATE INDEX CONCURRENTLY measurement_time_index ON electricity_measurements USING btree (measurement_time);
