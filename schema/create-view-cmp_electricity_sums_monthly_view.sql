CREATE VIEW electricity_cmp.cmp_electricity_sums_monthly_view AS (
    SELECT 
        date_part('year', start_date) AS year,
        date_part('month', start_date) AS month,
        sum(kwh) AS kwh
    FROM 
        electricity_cmp.cmp_electricity_sums_hourly
    GROUP BY 
        1, 2
    ORDER BY 
        1, 2
);
