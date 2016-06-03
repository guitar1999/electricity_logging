CREATE VIEW electricity_cmp.cmp_electricity_statistics_dow AS (
    SELECT 
        date_part('dow', sum_date) AS dow,
        m.season,
        avg(kwh) AS kwh_avg, 
        count(*) AS count 
    FROM 
        electricity_cmp.cmp_electricity_sums_daily_view e INNER JOIN 
        weather_data.meteorological_season m ON date_part('doy', e.sum_date)=m.doy
    GROUP BY 
        1, 2
    ORDER BY 
        2, 1
);