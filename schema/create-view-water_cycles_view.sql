CREATE OR REPLACE VIEW water_statistics.water_cycles_view AS (
    SELECT
        cycle_start,
        cycle_end,
        sum_date,
        hour,
        runtime
    FROM
        water_statistics.water_cycles
    UNION ALL
    SELECT
        wc.cycle_start,
        wc.cycle_end,
        wc.cycle_start::DATE AS sum_date,
        DATE_PART('HOUR', wc.cycle_start)::INTEGER AS hour,
        wc.runtime
    FROM
        water_completed_cycles(
            (DATE_TRUNC('HOUR', CURRENT_TIMESTAMP) - '1 HOUR 15 MINUTES'::INTERVAL)::TIMESTAMP,
            CURRENT_TIMESTAMP::TIMESTAMP
        ) wc
    WHERE
        NOT EXISTS (
            SELECT
                1
            FROM
                water_statistics.water_cycles stored
            WHERE
                stored.cycle_start = wc.cycle_start
        )
);
