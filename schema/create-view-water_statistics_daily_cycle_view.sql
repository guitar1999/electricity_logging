CREATE OR REPLACE VIEW water_statistics.water_statistics_daily_cycle_view AS (
    WITH cycle_runtimes AS (
        SELECT
            sum_date,
            runtime
        FROM
            water_statistics.water_cycle_runtimes_view
    ), daily AS (
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
            cycle_runtimes
        GROUP BY
            sum_date
    ), lifetime_median AS (
        SELECT
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY runtime) AS median_cycle_time
        FROM
            cycle_runtimes
    )
    SELECT
        d.sum_date,
        d.total_cycles,
        d.total_runtime,
        d.avg_cycle_time,
        dm.median_cycle_time,
        -- rolling averages over prior N days (including current)
        AVG(d.avg_cycle_time) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '6 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_7d,
        AVG(d.avg_cycle_time) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '29 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_30d,
        AVG(d.avg_cycle_time) OVER (
            ORDER BY d.sum_date::TIMESTAMP
            RANGE BETWEEN '89 days'::INTERVAL PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_90d,
        (
            SELECT
                PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY cr.runtime)
            FROM
                cycle_runtimes cr
            WHERE
                cr.sum_date BETWEEN d.sum_date - '89 days'::INTERVAL AND d.sum_date
        ) AS rolling_median_cycle_time_90d,
        lm.median_cycle_time AS lifetime_median_cycle_time
    FROM
        daily d
        LEFT JOIN daily_median dm ON d.sum_date = dm.sum_date,
        lifetime_median lm
    ORDER BY
        d.sum_date
);
