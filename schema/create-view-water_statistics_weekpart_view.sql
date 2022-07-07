CREATE OR REPLACE VIEW water_statistics.water_statistics_weekpart_view AS (
    SELECT 
        CASE is_weekend(sum_date) WHEN TRUE THEN 'weekend' ELSE 'weekday' END AS weekpart,
        m.season,
        avg(gallons) AS gallons_avg, 
        count(*) AS count 
    FROM 
        water_statistics.water_sums_daily_view e INNER JOIN 
        weather_data.meteorological_season m ON date_part('doy', e.sum_date)=m.doy
    GROUP BY 
        1, 2
    ORDER BY 
        2, 1
);