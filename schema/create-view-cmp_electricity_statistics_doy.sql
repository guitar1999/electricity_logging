CREATE VIEW electricity_cmp.cmp_electricity_statistics_doy AS (
    SELECT 
        date_part('month', sum_date) AS month,
        date_part('day', sum_date) AS day,
        avg(kwh) AS kwh_avg, 
        count(*) AS count 
    FROM 
        electricity_cmp.cmp_electricity_sums_daily_view
    GROUP BY 
        1, 2
    ORDER BY 
        1, 2
);