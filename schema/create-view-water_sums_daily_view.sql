CREATE OR REPLACE VIEW water_statistics.water_sums_daily_view AS (
    SELECT 
        sum_date,
        date_part('dow', sum_date) AS dow,
        sum(gallons) AS gallons,
        sum(cycles) AS cycles,
        sum(kwh) AS kwh
    FROM 
        water_statistics.water_sums_hourly_view
    GROUP BY 
        1, 2
    ORDER BY 
        1
);
