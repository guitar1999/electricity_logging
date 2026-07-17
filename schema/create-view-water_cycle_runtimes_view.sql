CREATE OR REPLACE VIEW water_statistics.water_cycle_runtimes_view AS (
    WITH bounds AS (
        SELECT
            MIN(sum_date)::TIMESTAMP AS start_time,
            CURRENT_TIMESTAMP::TIMESTAMP AS end_time
        FROM
            water_statistics.water_sums_hourly
    )
    SELECT
        MIN(w.measurement_time)::DATE AS sum_date,
        w.event_group,
        SUM(EXTRACT('EPOCH' FROM w.tdiff))::NUMERIC / 60 AS runtime
    FROM
        bounds b,
        water_status(b.start_time, b.end_time) w
    WHERE
        w.status = 'ON'
        AND w.event_group IS NOT NULL
    GROUP BY
        w.event_group
    ORDER BY
        sum_date,
        event_group
);
