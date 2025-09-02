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
    )
    SELECT
        sum_date,
        total_cycles,
        total_runtime,
        avg_cycle_time,
        -- rolling averages over prior N days (including current)
        AVG(avg_cycle_time) OVER (
            ORDER BY sum_date 
            ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_7d,
        AVG(avg_cycle_time) OVER (
            ORDER BY sum_date 
            ROWS BETWEEN 29 PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_30d,
        AVG(avg_cycle_time) OVER (
            ORDER BY sum_date 
            ROWS BETWEEN 89 PRECEDING AND CURRENT ROW
        ) AS rolling_avg_cycle_time_90d
    FROM daily
    ORDER BY sum_date
);