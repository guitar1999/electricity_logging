CREATE FUNCTION fix_tdiff(myemid INTEGER) RETURNS VOID AS
$$
BEGIN
    UPDATE 
        electricity.electricity_measurements 
    SET 
        tdiff = 
            (SELECT 
                date_part 
            FROM 
                (SELECT 
                    date_part('epoch', measurement_time - LAG(measurement_time) OVER (ORDER BY measurement_time)) 
                FROM 
                    electricity_measurements 
                WHERE 
                    emid IN (myemid,(
                        SELECT
                            MAX(emid)
                        FROM
                            electricity_measurements
                        WHERE
                            emid < myemid
                        )
                    )
                ) 
            AS 
                temp1 
            WHERE 
                NOT date_part IS NULL
            ) 
    WHERE 
        emid = myemid;
END;
$$
LANGUAGE plpgsql
