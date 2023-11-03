CREATE OR REPLACE VIEW water_plotting.water_cumulative_averages AS (
    SELECT
        gs.hourlies AS timestamp,
        SUM(x.avg_gallons) OVER (PARTITION BY x.month ORDER BY x.month, x.day, x.hour) AS monthly_cum_avg_gallons,
        SUM(x.avg_gallons) OVER (ORDER BY x.month, x.day, x.hour) AS cum_avg_gallons
    FROM
        (SELECT 
            DATE_PART('MONTH', sum_date) AS month,
            DATE_PART('DAY', sum_date) AS day,
            hour,
            avg(gallons) AS avg_gallons
        FROM 
            water_statistics.water_sums_hourly_view
        GROUP BY 
            month,
            day,
            hour
        ORDER BY 
            month,
            day,
            hour
        ) AS x
        INNER JOIN
        (SELECT
            generate_series AS hourlies
        FROM
            generate_series(DATE_TRUNC('YEAR', CURRENT_DATE), DATE_TRUNC('YEAR', CURRENT_DATE + INTERVAL '1 YEAR') - INTERVAL '1 HOUR', INTERVAL '1 HOUR')
        ) AS gs ON x.month = DATE_PART('MONTH', gs.hourlies) AND x.day = DATE_PART('DAY', gs.hourlies) AND x.hour = DATE_PART('HOUR', gs.hourlies)
);
