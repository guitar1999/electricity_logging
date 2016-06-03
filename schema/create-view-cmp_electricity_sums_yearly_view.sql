CREATE VIEW electricity_cmp.cmp_electricity_sums_yearly_view AS (
    SELECT 
        date_part('year', start_date) AS year,
        sum(kwh) AS kwh
    FROM 
        electricity_cmp.cmp_electricity_sums_hourly
    GROUP BY 
        1
    ORDER BY 
        1
);
