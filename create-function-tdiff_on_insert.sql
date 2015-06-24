CREATE OR REPLACE FUNCTION tdiff_on_insert() RETURNS TRIGGER AS 
$$
    BEGIN
        UPDATE electricity_measurements SET tdiff = (SELECT date_part FROM (SELECT date_part('epoch', measurement_time - LAG(measurement_time) OVER (ORDER BY measurement_time)) FROM electricity_measurements WHERE emid = NEW.emid OR emid = (SELECT MAX(emid) FROM electricity_measurements WHERE emid < NEW.emid)) AS temp1 WHERE NOT date_part IS NULL) WHERE emid = NEW.emid;
        RETURN NEW;
    END;
$$
LANGUAGE PLPGSQL VOLATILE;


DROP TRIGGER IF EXISTS tdiff_on_insert ON electricity_measurements;
CREATE TRIGGER tdiff_on_insert
    AFTER INSERT ON electricity_measurements FOR EACH ROW EXECUTE PROCEDURE tdiff_on_insert();