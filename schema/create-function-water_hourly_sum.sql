CREATE OR REPLACE FUNCTION water_hourly_sum() RETURNS TRIGGER AS 
$$
    DECLARE
        old_hour INTEGER;
    BEGIN
        SELECT DATE_PART('HOUR', (SELECT MAX(measurement_time) FROM electricity_iotawatt.electricity_measurements WHERE NOT emid = NEW.emid)) INTO old_hour;
        IF old_hour != DATE_PART('HOUR', NEW.measurement_time) THEN
            INSERT INTO water_statistics.water_sums_hourly (sum_date, hour, kwh, gallons, cycles, total_runtime, avg_runtime, min_runtime, max_runtime)
            SELECT (DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)::DATE AS sum_date,
                DATE_PART('HOUR', DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL) AS hour,
                ws.*
            FROM water_summary( (DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)::TIMESTAMP, (DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)::TIMESTAMP + '00:59:59'::INTERVAL ) AS ws;
            RETURN NEW;
        ELSE
            RETURN NEW;
        END IF;
    END;
$$
LANGUAGE PLPGSQL VOLATILE;


DROP TRIGGER IF EXISTS water_hourly_sum ON electricity_iotawatt.electricity_measurements;
CREATE TRIGGER water_hourly_sum
    AFTER INSERT ON electricity_iotawatt.electricity_measurements FOR EACH ROW EXECUTE PROCEDURE water_hourly_sum();