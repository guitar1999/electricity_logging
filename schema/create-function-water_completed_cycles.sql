CREATE OR REPLACE FUNCTION public.water_completed_cycles(start_time TIMESTAMP, end_time TIMESTAMP)
RETURNS TABLE(cycle_start TIMESTAMP WITH TIME ZONE, cycle_end TIMESTAMP WITH TIME ZONE, runtime NUMERIC)
AS $$
    WITH measurements AS (
        SELECT
            em.measurement_time,
            CASE
                WHEN em.watts_water_pump > 10 THEN 'ON'
                ELSE 'OFF'
            END AS status
        FROM (
            (
                SELECT
                    measurement_time,
                    watts_water_pump
                FROM
                    electricity_iotawatt.electricity_measurements
                WHERE
                    measurement_time < start_time
                    AND watts_water_pump IS NOT NULL
                ORDER BY
                    measurement_time DESC
                LIMIT 1
            )
            UNION ALL
            (
                SELECT
                    measurement_time,
                    watts_water_pump
                FROM
                    electricity_iotawatt.electricity_measurements
                WHERE
                    measurement_time >= start_time
                    AND measurement_time <= end_time
                    AND watts_water_pump IS NOT NULL
            )
        ) em
    ), state AS (
        SELECT
            measurement_time,
            status,
            LAG(status) OVER (ORDER BY measurement_time) AS previous_status
        FROM
            measurements
    ), starts AS (
        SELECT
            measurement_time AS cycle_start
        FROM
            state
        WHERE
            status = 'ON'
            AND COALESCE(previous_status, 'OFF') <> 'ON'
            AND measurement_time >= start_time
    )
    SELECT
        s.cycle_start,
        e.cycle_end,
        EXTRACT('EPOCH' FROM e.cycle_end - s.cycle_start)::NUMERIC / 60 AS runtime
    FROM
        starts s
        CROSS JOIN LATERAL (
            SELECT
                state.measurement_time AS cycle_end
            FROM
                state
            WHERE
                state.measurement_time > s.cycle_start
                AND state.status = 'OFF'
            ORDER BY
                state.measurement_time
            LIMIT 1
        ) e
    WHERE
        e.cycle_end <= end_time
    ORDER BY
        s.cycle_start;
$$ LANGUAGE SQL STABLE;
