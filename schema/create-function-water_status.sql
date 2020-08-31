CREATE OR REPLACE FUNCTION public.water_status(start_time TIMESTAMP, end_time TIMESTAMP)
RETURNS TABLE(measurement_time TIMESTAMP WITH TIME ZONE, watts_water_pump NUMERIC, tdiff INTERVAL, status TEXT, event_group BIGINT, gallons NUMERIC)
AS $$
-- Declare an empty variable to hold the initial state of the system and some constants to be used in calculations.
DECLARE

    pump_gpm NUMERIC := 7.7;

BEGIN

   RETURN QUERY WITH status_query AS (
        SELECT
            em.measurement_time,
            em.watts_water_pump,
            em.measurement_time - LAG(em.measurement_time) OVER (ORDER BY em.measurement_time) AS tdiff,
            CASE
                WHEN em.watts_water_pump > 10 THEN 'ON'
                ELSE 'OFF'
            END AS status
        FROM
            electricity_iotawatt.electricity_measurements em
        WHERE
            em.measurement_time >= start_time
            AND em.measurement_time <= end_time
            AND NOT em.watts_water_pump IS NULL
        ORDER BY em.measurement_time
    ), event_group_query AS (
        SELECT
            sq.measurement_time,
            sq.watts_water_pump,
            sq.tdiff,
            sq.status,
            CASE
                WHEN sq.status = 'ON' AND NOT LAG(sq.status) OVER (ORDER BY sq.measurement_time) = 'ON' THEN DATE_PART('EPOCH', sq.measurement_time)
                ELSE NULL
            END AS event_group
        FROM
            status_query sq
    ), event_group2_query AS (
        SELECT
            egq.measurement_time,
            egq.watts_water_pump,
            egq.tdiff,
            egq.status,
            egq.event_group,
            CASE
                WHEN egq.status = 'OFF' THEN NULL
                ELSE SUM(CASE WHEN egq.event_group IS NULL THEN 0 ELSE 1 END) OVER (ORDER BY egq.measurement_time)
            END AS event_group2
        FROM
            event_group_query egq
    ) SELECT
        egq2.measurement_time,
        egq2.watts_water_pump,
        egq2.tdiff,
        egq2.status,
        egq2.event_group2 AS event_group,
        CASE
            WHEN egq2.status = 'ON' THEN (pump_gpm * DATE_PART('EPOCH', egq2.tdiff) / 60)::NUMERIC
            ELSE 0::NUMERIC
        END AS gallons
    FROM
        event_group2_query egq2
    ;
END;
$$ LANGUAGE plpgsql IMMUTABLE;
