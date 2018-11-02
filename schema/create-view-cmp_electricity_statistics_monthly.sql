CREATE OR REPLACE VIEW electricity_cmp.cmp_electricity_statistics_monthly AS (
    SELECT 
        month,
        avg(kwh) AS kwh_avg, 
        count(*) AS count 
    FROM 
        electricity_cmp.cmp_electricity_sums_monthly_view
    WHERE
        ((year = 2016 AND month >= 7) OR year > 2016) -- filter first few months where usage wasn't ramped up yet
        AND complete = 'yes'
    GROUP BY 
        1
    ORDER BY 
        1
);
