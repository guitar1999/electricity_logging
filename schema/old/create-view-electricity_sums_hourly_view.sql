CREATE OR REPLACE VIEW electricity_statistics.electricity_sums_hourly_view AS (
    SELECT 
        measurement_time::DATE AS sum_date, 
        DATE_PART('hour', measurement_time) AS hour, 
        SUM((watts_ch1 + watts_ch2) * tdiff / 1000 / 60 / 60) AS kwh, 
        CASE 
            WHEN MIN(DATE_PART('minute', measurement_time)) < 3 AND MAX(DATE_PART('minute', measurement_time)) > 58 AND MAX(tdiff) < 300 THEN 'yes' 
            ELSE 'no' 
        END AS complete 
    FROM 
        electricity_measurements 
    GROUP BY 
        1,
        2 
    ORDER BY 
        1 DESC, 
        2 DESC
);
