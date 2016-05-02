CREATE VIEW electricity_statistics.electricity_sums_hourly_cmp_view AS (
    SELECT 
        start_date::date AS sum_date,
        date_part('hour', start_date) AS hour,
        kwh
    FROM 
        electricity_statistics.electricity_sums_hourly_cmp
    ORDER BY 1
);
