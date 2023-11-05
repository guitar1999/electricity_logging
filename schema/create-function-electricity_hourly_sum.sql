CREATE OR REPLACE FUNCTION electricity_hourly_sum() RETURNS TRIGGER AS 
$$
    DECLARE
        old_hour INTEGER;
    BEGIN
        SELECT DATE_PART('HOUR', (SELECT MAX(measurement_time) FROM electricity.electricity_measurements WHERE NOT emid = NEW.emid)) INTO old_hour;
        IF old_hour != DATE_PART('HOUR', NEW.measurement_time) THEN
            INSERT INTO 
                electricity_statistics.electricity_sums_hourly (sum_date, hour, kwh)
            SELECT 
                (DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)::DATE AS sum_date,
                DATE_PART('HOUR', DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL) AS hour,
                COALESCE(SUM((watts_ch1 + watts_ch2) * tdiff / 1000 / 60 / 60), 0) AS kwh
            FROM 
                electricity.electricity_measurements
            WHERE 
                measurement_time > NEW.measurement_time - INTERVAL '1 DAY'
                AND measurement_time::DATE = (DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)::DATE
                AND DATE_PART('HOUR', measurement_time) = DATE_PART('HOUR', DATE_TRUNC('HOUR', NEW.measurement_time) - '1 HOUR'::INTERVAL)
            GROUP BY 1,
                    2
            ON CONFLICT (sum_date, hour) DO
            UPDATE SET kwh = EXCLUDED.kwh;
            RETURN NEW;
        ELSE
            RETURN NEW;
        END IF;
    END;
$$
LANGUAGE PLPGSQL VOLATILE;


DROP TRIGGER IF EXISTS electricity_hourly_sum ON electricity.electricity_measurements;
CREATE TRIGGER electricity_hourly_sum
    AFTER INSERT ON electricity.electricity_measurements FOR EACH ROW EXECUTE PROCEDURE electricity_hourly_sum();