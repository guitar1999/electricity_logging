CREATE OR REPLACE VIEW water_statistics.water_sums_hourly_view AS (
    SELECT
        sum_date,
        hour,
        gallons,
        cycles,
        kwh
    FROM
        (SELECT
            sum_date,
            hour,
            gallons,
            cycles,
            kwh
        FROM
            water_statistics.water_sums_hourly
        UNION
        SELECT
            CURRENT_TIMESTAMP::DATE AS sum_date,
            DATE_PART('HOUR', CURRENT_TIMESTAMP)::INTEGER AS hour,
            gallons AS gallons,
            cycles,
            kwh
        FROM
            water_summary(DATE_TRUNC('HOUR', CURRENT_TIMESTAMP)::TIMESTAMP, CURRENT_TIMESTAMP::TIMESTAMP)
        ) AS x
    ORDER BY 1, 2
);
