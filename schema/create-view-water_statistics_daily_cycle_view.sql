CREATE OR REPLACE VIEW water_statistics.water_statistics_daily_cycle_view AS (
    SELECT 
        sum_date
        , sum(cycles) AS total_cycles
        , sum(total_runtime) AS total_runtime
        , sum(total_runtime) / sum(cycles) AS avg_cycle_time 
    FROM 
        water_statistics.water_sums_hourly 
    WHERE 
        cycles > 0 
    GROUP BY 
        sum_date
    ORDER BY
        sum_date
);