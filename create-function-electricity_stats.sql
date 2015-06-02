CREATE OR REPLACE FUNCTION electricity_stats()
RETURNS TABLE(date DATE, kwh_day NUMERIC, kwh_last_year_day NUMERIC, avg_kwh_day NUMERIC, kwh_month NUMERIC, kwh_last_year_month NUMERIC, kwh_avg_month NUMERIC, prediction NUMERIC)
AS $$
BEGIN
RETURN QUERY 
WITH 
    month AS (
        SELECT 
            u.month, 
            ROUND(u.kwh, 2) AS kwh, 
            ROUND(u.kwh_avg, 2) AS kwh_avg, 
            s.count, 
            ROUND(s.previous_year, 2) AS previous_year, 
            u.complete, 
            DATE_TRUNC('second', u.timestamp) AS timestamp 
        FROM 
            electricity_usage_monthly u 
            INNER JOIN electricity_statistics_monthly s ON u.month=s.month 
        WHERE 
            u.month = date_part('month', CURRENT_TIMESTAMP)),
    day AS (
        SELECT 
            day_of_week, 
            ROUND(kwh, 2) AS kwh, 
            ROUND(kwh_avg, 2) AS kwh_avg, 
            complete, 
            DATE_TRUNC('second', timestamp) AS timestamp 
        FROM 
            electricity_usage_dow 
        WHERE 
            dow = date_part('dow', CURRENT_TIMESTAMP)),
    pred AS (
        SELECT 
            DATE_TRUNC('second', time) AS prediction_time, 
            minuteh AS prediction 
        FROM 
            prediction_test 
        WHERE time = (SELECT max(time) FROM prediction_test)),
    doy AS (
        SELECT 
            ROUND(previous_year, 2) AS previous_year
        FROM 
            electricity_statistics_doy 
        WHERE 
            month = date_part('month', CURRENT_TIMESTAMP) AND
            day = date_part('day', CURRENT_TIMESTAMP))
    SELECT
        CURRENT_TIMESTAMP::date AS date,
        day.kwh AS kwh_day,
        doy.previous_year AS kwh_last_year_day,
        day.kwh_avg AS avg_kwh_day,
        month.kwh AS kwh_month,
        month.previous_year AS kwh_last_year_month,
        month.kwh_avg AS kwh_avg_month,
        pred.prediction AS prediction
    FROM
        day, 
        doy, 
        month, 
        pred;
END;
$$ LANGUAGE plpgsql;
