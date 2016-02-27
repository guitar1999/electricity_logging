CREATE OR REPLACE FUNCTION increment_usage(tablename text, columnname text) RETURNS numeric AS $$
--input table name, column name
DECLARE
    temp1 numeric;
    year1 text;
BEGIN
    IF columnname LIKE 'doy%' THEN
        year1 := 'doy';
    ELSE
        year1 := columnname;
    END IF;
    EXECUTE 'UPDATE '
        || tablename
    || ' SET 
        kwh=x.skwh, 
        timestamp=CURRENT_TIMESTAMP
    FROM 
        (SELECT 
            ((SELECT 
                kwh
            FROM '
                || tablename
            || ' WHERE '
                || columnname || ' = date_part(''' || year1 ||''', CURRENT_TIMESTAMP - interval ''4 hours'')
            ) +
            (SELECT COALESCE(SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.), 0) 
        FROM 
            electricity_measurements 
        WHERE 
            measurement_time > 
            (SELECT
                timestamp
            FROM '
                || tablename
            || ' WHERE '
                || columnname || ' = date_part(''' || year1 || ''', CURRENT_TIMESTAMP - interval ''4 hours'')
            ))
            ) AS skwh
        ) AS x
    WHERE '
        || columnname || ' = date_part(''' || year1 || ''', CURRENT_TIMESTAMP - interval ''4 hours'')
    RETURNING 
        x.skwh' INTO temp1;
    RETURN temp1;

END;
$$ LANGUAGE 'plpgsql';
