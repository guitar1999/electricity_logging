CREATE VIEW electricity_cmp.cmp_electricity_statistics_hourly AS (
    SELECT 
        date_part('dow', sum_date) AS dow,
        m.season,
        hour, 
        avg(kwh) AS kwh_avg, 
        count(*) AS count 
    FROM 
        electricity_cmp.cmp_electricity_sums_hourly_view e INNER JOIN 
        weather_data.meteorological_season m ON date_part('doy', e.sum_date)=m.doy
    GROUP BY 
        1, 2, 3
    ORDER BY 
        2, 1, 3
);