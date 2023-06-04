CREATE OR REPLACE VIEW electricity_iotawatt_statistics.electricity_minimums_daily_view AS (
    SELECT
        sum_date,
        MIN(watts) AS watts
    FROM
        electricity_iotawatt_statistics.electricity_minimums_hourly
    GROUP BY
        sum_date
    ORDER BY
        sum_date
);