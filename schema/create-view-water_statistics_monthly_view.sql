CREATE OR REPLACE VIEW water_statistics.water_statistics_monthly_view AS (
    SELECT 
        month,
        avg(gallons) AS gallons_avg, 
        count(*) AS count 
    FROM 
        water_statistics.water_sums_monthly_view
    WHERE
        ((year = 2020 AND month >= 5) OR year > 2020) -- filter where partial usage
        AND complete = 'yes'
    GROUP BY 
        1
    ORDER BY 
        1
);
