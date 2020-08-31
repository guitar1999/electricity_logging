CREATE OR REPLACE VIEW water_statistics.water_sums_yearly_view AS (
    SELECT 
        date_part('year', sum_date) AS year,
        sum(gallons) AS gallons,
        sum(cycles) AS cycles,
        sum(kwh) AS kwh,
        CASE
            WHEN COUNT(*) / 24. > 364 THEN 'yes'
            ELSE 'no'
        END AS complete
    FROM 
        water_statistics.water_sums_hourly_view
    GROUP BY 
        1
    ORDER BY 
        1
);
