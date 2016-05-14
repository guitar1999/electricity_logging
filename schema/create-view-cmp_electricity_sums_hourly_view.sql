CREATE VIEW electricity_cmp.cmp_electricity_sums_hourly_view AS (
    SELECT 
        start_date::date AS sum_date,
        date_part('hour', start_date) AS hour,
        kwh
    FROM 
        electricity_cmp.cmp_electricity_sums_hourly
    ORDER BY 1
);
