CREATE OR REPLACE VIEW electricity_iotawatt_statistics.electricity_sums_hourly_view AS (
    SELECT
        sum_date,
        hour,
        kwh,
        generator_usage
    FROM
        electricity_iotawatt_statistics.electricity_sums_hourly
    UNION ALL
    SELECT 
        CURRENT_DATE AS sum_date,
        DATE_PART('hour', CURRENT_TIMESTAMP) AS hour,
        SUM((watts_main_1 + watts_main_2 + watts_generator_1 + watts_generator_2) * tdiff / 1000. / 60 / 60) AS kwh,
        BOOL_OR(watts_generator_1 + watts_generator_2 > 0) AS generator_usage
    FROM 
        electricity_iotawatt.electricity_measurements
    WHERE 
        measurement_time >= CURRENT_DATE
        AND DATE_PART('hour', measurement_time) = DATE_PART('hour', CURRENT_TIMESTAMP)
);