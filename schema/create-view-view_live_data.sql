CREATE OR REPLACE VIEW electricity.view_live_data AS (
SELECT
    watts_ch1 + watts_ch2 AS watts,
    watts_ch3,
    measurement_time
FROM
    electricity_measurements
WHERE
    measurement_time > (CURRENT_TIMESTAMP) - ((DATE_PART('minute', (CURRENT_TIMESTAMP)) + 60) * INTERVAL '1 minute') - (DATE_PART('second', (CURRENT_TIMESTAMP)) * INTERVAL '1 second')
ORDER BY
    measurement_time
);