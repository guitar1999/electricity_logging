CREATE OR REPLACE VIEW water_statistics.water_statistics_daily_cycle_view AS (
    WITH daily AS (
        SELECT 
            sum_date,
            SUM(cycles) AS total_cycles,
            SUM(total_runtime) AS total_runtime,
            SUM(total_runtime) / SUM(cycles) AS avg_cycle_time
        FROM water_statistics.water_sums_hourly
        WHERE cycles > 0
        GROUP BY sum_date
    ), daily_median AS (
        SELECT
            sum_date,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY runtime) AS median_cycle_time
        FROM
            water_statistics.water_cycles
        GROUP BY
            sum_date
    ), lifetime_median AS (
        SELECT
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY runtime) AS median_cycle_time
        FROM
            water_statistics.water_cycles
    )
    SELECT
        d.sum_date,
        d.total_cycles,
        d.total_runtime,
        d.avg_cycle_time,
        dm.median_cycle_time,
        SUM(d.total_cycles) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '6 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_cycles_7d,
        SUM(d.total_cycles) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '29 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_cycles_30d,
        SUM(d.total_cycles) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '89 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_cycles_90d,
        SUM(d.total_runtime) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '6 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_runtime_7d,
        SUM(d.total_runtime) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '29 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_runtime_30d,
        SUM(d.total_runtime) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '89 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_runtime_90d,
        SUM(d.total_runtime) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '6 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) / SUM(d.total_cycles) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '6 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_7d,
        SUM(d.total_runtime) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '29 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) / SUM(d.total_cycles) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '29 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_30d,
        SUM(d.total_runtime) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '89 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) / SUM(d.total_cycles) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '89 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_90d,
        (
            SELECT
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dd.total_cycles)
            FROM
                daily dd
            WHERE
                dd.sum_date BETWEEN d.sum_date - '6 days'::INTERVAL AND d.sum_date
        ) AS rolling_cycles_median_7d,
        (
            SELECT
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dd.total_cycles)
            FROM
                daily dd
            WHERE
                dd.sum_date BETWEEN d.sum_date - '29 days'::INTERVAL AND d.sum_date
        ) AS rolling_cycles_median_30d,
        (
            SELECT
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dd.total_cycles)
            FROM
                daily dd
            WHERE
                dd.sum_date BETWEEN d.sum_date - '89 days'::INTERVAL AND d.sum_date
        ) AS rolling_cycles_median_90d,
        (
            SELECT
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dd.total_runtime)
            FROM
                daily dd
            WHERE
                dd.sum_date BETWEEN d.sum_date - '6 days'::INTERVAL AND d.sum_date
        ) AS rolling_runtime_median_7d,
        (
            SELECT
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dd.total_runtime)
            FROM
                daily dd
            WHERE
                dd.sum_date BETWEEN d.sum_date - '29 days'::INTERVAL AND d.sum_date
        ) AS rolling_runtime_median_30d,
        (
            SELECT
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY dd.total_runtime)
            FROM
                daily dd
            WHERE
                dd.sum_date BETWEEN d.sum_date - '89 days'::INTERVAL AND d.sum_date
        ) AS rolling_runtime_median_90d,
        AVG(dm.median_cycle_time) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '6 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_median_7d,
        AVG(dm.median_cycle_time) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '29 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_median_30d,
        AVG(dm.median_cycle_time) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '89 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_median_90d,
        lm.median_cycle_time AS lifetime_median_cycle_time
    FROM
        daily d
        LEFT JOIN daily_median dm ON d.sum_date = dm.sum_date,
        lifetime_median lm
    ORDER BY
        d.sum_date
);
