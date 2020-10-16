CREATE OR REPLACE VIEW electricity_statistics.electricity_sums_hourly_view AS (
    SELECT
        sum_date,
        hour,
        kwh
    FROM
        electricity_statistics.electricity_sums_hourly
    UNION ALL
    SELECT 
        CURRENT_DATE AS sum_date,
        DATE_PART('hour', CURRENT_TIMESTAMP) AS hour,
        SUM((watts_ch1 + watts_ch2) * tdiff / 1000. / 60 / 60) AS kwh
    FROM 
        electricity.electricity_measurements
    WHERE 
        measurement_time >= CURRENT_DATE
        AND DATE_PART('hour', measurement_time) = DATE_PART('hour', CURRENT_TIMESTAMP)
);