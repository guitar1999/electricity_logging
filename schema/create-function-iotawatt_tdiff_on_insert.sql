CREATE OR REPLACE FUNCTION iotawatt_tdiff_on_insert() RETURNS TRIGGER AS 
$$
    BEGIN
        UPDATE electricity_iotawatt.electricity_measurements 
        SET tdiff = 
            (SELECT 
                tdiff
            FROM
                (SELECT 
                    DATE_PART('epoch', measurement_time - LAG(measurement_time) OVER (
            ORDER BY measurement_time)) AS tdiff
                FROM 
                    electricity_iotawatt.electricity_measurements
                WHERE 
                    measurement_time = NEW.measurement_time
                    OR measurement_time =
                        (SELECT 
                            MAX(measurement_time)
                        FROM 
                            electricity_iotawatt.electricity_measurements
                        WHERE 
                            measurement_time < NEW.measurement_time
                        )
                ) AS temp1
            WHERE 
                NOT tdiff IS NULL
            ) 
        WHERE 
            emid = NEW.emid;
        RETURN NEW;
    END;
$$
LANGUAGE PLPGSQL VOLATILE;


DROP TRIGGER IF EXISTS iotawatt_tdiff_on_insert ON electricity_iotawatt.electricity_measurements;
CREATE TRIGGER iotawatt_tdiff_on_insert
    AFTER INSERT ON electricity_iotawatt.electricity_measurements FOR EACH ROW EXECUTE PROCEDURE iotawatt_tdiff_on_insert();