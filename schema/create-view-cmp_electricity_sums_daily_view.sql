CREATE VIEW electricity_cmp.cmp_electricity_sums_daily_view AS (
    SELECT 
        start_date::date AS sum_date,
        date_part('dow', start_date) AS dow,
        sum(kwh) AS kwh
    FROM 
        electricity_cmp.cmp_electricity_sums_hourly
    GROUP BY 
        1, 2
    ORDER BY 
        1
);
