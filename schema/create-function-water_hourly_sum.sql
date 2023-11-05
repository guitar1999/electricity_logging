CREATE OR REPLACE FUNCTION water_hourly_sum() RETURNS TRIGGER AS 
$$
    DECLARE
        old_hour INTEGER;
    BEGIN
        SELECT DATE_PART('HOUR', (SELECT MAX(measurement_time) FROM electricity_iotawatt.electricity_measurements WHERE NOT emid = NEW.emid AND measurement_time < NEW.measurement_time)) INTO old_hour;
        IF (old_hour = DATE_PART('HOUR', NEW.measurement_time) - 1) OR (old_hour = 23 AND DATE_PART('HOUR', NEW.measurement_time) = 0) THEN
            INSERT INTO water_statistics.water_sums_hourly (sum_date, hour, kwh, gallons, cycles, total_runtime, avg_runtime, min_runtime, max_runtime)
            SELECT (DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)::DATE AS sum_date,
                DATE_PART('HOUR', DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL) AS hour,
                COALESCE(ws.kwh, 0),
                COALESCE(ws.gallons, 0),
                COALESCE(ws.cycles, 0),
                COALESCE(ws.total_runtime, 0),
                COALESCE(ws.avg_runtime, 0),
                COALESCE(ws.min_runtime, 0),
                COALESCE(ws.max_runtime, 0)
            FROM water_summary( (DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)::TIMESTAMP, (DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)::TIMESTAMP + '00:59:59'::INTERVAL ) AS ws
            ON CONFLICT (sum_date, hour) DO
            UPDATE SET (kwh, gallons, cycles, total_runtime, avg_runtime, min_runtime, max_runtime) = (EXCLUDED.kwh, EXCLUDED.gallons, EXCLUDED.cycles, EXCLUDED.total_runtime, EXCLUDED.avg_runtime, EXCLUDED.min_runtime, EXCLUDED.max_runtime);
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