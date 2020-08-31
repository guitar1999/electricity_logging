CREATE OR REPLACE VIEW water_statistics.water_statistics_doy_view AS (
    SELECT 
        date_part('month', sum_date) AS month,
        date_part('day', sum_date) AS day,
        avg(gallons) AS gallons_avg, 
        count(*) AS count 
    FROM 
        water_statistics.water_sums_daily_view
    GROUP BY 
        1, 2
    ORDER BY 
        1, 2
);