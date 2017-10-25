CREATE VIEW weather_data.weather_avg_hdd_view AS (
    SELECT
        DATE_PART('DOY', weather_date) AS doy,
        AVG(hdd) AS hdd_avg,
        COUNT(*) AS count
    FROM
        weather_data.weather_daily_mean_data
    GROUP BY
        1
);
