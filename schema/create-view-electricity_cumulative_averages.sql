CREATE OR REPLACE VIEW electricity_plotting.electricity_cumulative_averages AS (
    SELECT
        gs.hourlies AS timestamp,
        SUM(x.avg_kwh) OVER (PARTITION BY x.month ORDER BY x.month, x.day, x.hour) AS monthly_cum_avg_kwh,
        SUM(x.avg_kwh) OVER (ORDER BY x.month, x.day, x.hour) AS cum_avg_kwh
    FROM
        (SELECT 
            DATE_PART('MONTH', sum_date) AS month,
            DATE_PART('DAY', sum_date) AS day,
            hour,
            avg(kwh) AS avg_kwh
        FROM 
            electricity_cmp.cmp_electricity_sums_hourly_view
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
