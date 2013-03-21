CREATE VIEW electricity_usage AS
SELECT 
	watts, 
	LAG(time) OVER (ORDER BY time) AS start_time, 
	time AS end_time, 
	date_part('epoch', time - LAG(time) OVER (ORDER BY time)) AS seconds, 
	watts * date_part('epoch', time - LAG(time) OVER (ORDER BY time)) / 60 / 60 / 1000. AS kwh 
FROM 
	temp_electricity
;

