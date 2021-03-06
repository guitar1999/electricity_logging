CREATE OR REPLACE VIEW water_statistics.water_statistics_hourly_view AS (
    SELECT 
        date_part('dow', sum_date) AS dow,
        m.season,
        hour, 
        avg(gallons) AS gallons_avg, 
        count(*) AS count 
    FROM 
        water_statistics.water_sums_hourly_view e INNER JOIN 
        weather_data.meteorological_season m ON date_part('doy', e.sum_date)=m.doy
    GROUP BY 
        1, 2, 3
    ORDER BY 
        2, 1, 3
);