CREATE VIEW electricity_cmp.cmp_electricity_statistics_monthly AS (
    SELECT 
        month,
        avg(kwh) AS kwh_avg, 
        count(*) AS count 
    FROM 
        electricity_cmp.cmp_electricity_sums_monthly_view
    GROUP BY 
        1
    ORDER BY 
        1
);