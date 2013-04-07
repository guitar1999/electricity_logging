-- Get all data for the last hour
SELECT watts_ch1 + watts_ch2, watts_ch1, watts_ch2, watts_ch3, measurement_time FROM electricity_measurements WHERE mreasurement_time > CURRENT_TIMESTAMP - interval '1 hour';

-- Get hourly data for the previous day
SELECT sum(watts_ch1 + watts_ch2), sum(watts_ch1), sum(watts_ch2), sum(watts_ch3), date_part('hour', measurement_time) FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '1 day' GROUP BY date_part('hour', measurement_time);

-- Using the new view (currently on the temp_electricity table)
SELECT SUM(kwh) FROM electricity_usage WHERE start_time > CURRENT_TIMESTAMP - interval '1 day';
SELECT SUM(kwh) FROM electricity_usage WHERE start_time > CURRENT_TIMESTAMP - interval '1 hour';
SELECT SUM(kwh), date_part('hour', end_time) AS hour FROM electricity_usage  WHERE start_time > CURRENT_TIMESTAMP - interval '1 day' GROUP BY hour;
SELECT SUM(kwh), date_part('doy', end_time) AS doy FROM electricity_usage GROUP BY doy;
SELECT SUM(kwh), date_part('month', end_time) AS month FROM electricity_usage GROUP BY month;

-- USING the NEW table columns
SELECT watts * tdiff / 60 / 60 / 1000. AS kwh, time FROM temp_electricity WHERE time > CURRENT_TIMESTAMP - interval '1 hour';

-- SCRATCH SPACE
select time, time - lag(time) over (order by time) from temp_electricity ;
SELECT round(sum(watts)/count(watts)/1000., 4) AS kwh, date_part('hour', time) AS hod FROM temp_electricity WHERE time > CURRENT_TIMESTAMP - interval
 '3 days' AND time <= CURRENT_TIMESTAMP - interval '2 days' GROUP BY hod ORDER BY hod;

SELECT round(sum(watts)/count(watts)*24/1000., 4) AS kwh, date_part('day', time) AS hod FROM temp_electricity GROUP BY hod ORDER BY hod;

SELECT SUM(kwh), date_part('hour', end_time) AS hour, to_timestamp(min(date_part('year', end_time))::text || '/' || min(date_part('month', end_time))::text || '/' || min(date_part('day', end_time))::text || ' ' || date_part('hour', end_time)::text || ':00:00', 'YYYY/MM/DD HH24:MI:SS') AS date  FROM electricity_usage  WHERE start_time > CURRENT_TIMESTAMP - interval '1 day' GROUP BY hour ORDER BY date;
