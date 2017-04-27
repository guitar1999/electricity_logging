CREATE OR REPLACE VIEW electricity_statistics.electricity_sums_hourly_modeling_view AS (
    SELECT 
        measurement_time::DATE AS sum_date, 
        DATE_PART('hour', measurement_time) AS hour, 
        SUM(watts_ch1 * tdiff / 1000 / 60 / 60) AS kwh_ch1,
        SUM(watts_ch2 * tdiff / 1000 / 60 / 60) AS kwh_ch2,
        SUM(watts_ch3 * tdiff / 1000 / 60 / 60) AS kwh_ch3
    FROM 
        electricity_measurements 
    GROUP BY 
        1,
        2 
    ORDER BY 
        1 DESC, 
        2 DESC
);
