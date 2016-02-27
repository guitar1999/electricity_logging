CREATE VIEW electricity_usage AS
SELECT 
	(watts_ch1 + watts_ch2), 
	LAG(measurement_time) OVER (ORDER BY measurement_time) AS start_time, 
	measurement_time AS end_time, 
	date_part('epoch', measurement_time - LAG(measurement_time) OVER (ORDER BY measurement_time)) AS seconds, 
	(watts_ch1 + watts_ch2) * date_part('epoch', measurement_time - LAG(measurement_time) OVER (ORDER BY measurement_time)) / 60 / 60 / 1000. AS kwh 
FROM 
	electricity_measurements
;

