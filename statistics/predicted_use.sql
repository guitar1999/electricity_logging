WITH days_in_month AS (SELECT date_part('days', date_trunc('month', CURRENT_TIMESTAMP) + interval '1 month' - date_trunc('month', CURRENT_TIMESTAMP)) AS days_in_month),
elapsed_seconds AS (SELECT date_part('epoch', timestamp - date_trunc('month', CURRENT_TIMESTAMP)) AS elapsed_seconds FROM electricity_usage_monthly WHERE month = date_part('month', CURRENT_TIMESTAMP)),
day AS (SELECT round((kwh / date_part('day', CURRENT_TIMESTAMP) * days_in_month.days_in_month)::numeric, 2) AS projected_use FROM electricity_usage_monthly, days_in_month WHERE month = date_part('month', CURRENT_TIMESTAMP)), 
hour AS (SELECT round((kwh / floor(elapsed_seconds.elapsed_seconds / 60 / 60) * days_in_month.days_in_month * 24)::numeric, 2) AS projected_use FROM electricity_usage_monthly, days_in_month, elapsed_seconds WHERE month = date_part('month', CURRENT_TIMESTAMP)), 
minute AS (SELECT round((kwh / floor(elapsed_seconds.elapsed_seconds / 60) * days_in_month.days_in_month * 24 * 60)::numeric, 2) AS projected_use FROM electricity_usage_monthly, days_in_month, elapsed_seconds WHERE month = date_part('month', CURRENT_TIMESTAMP)), 
lookback AS (SELECT CASE WHEN date_part('day', CURRENT_TIMESTAMP) > 11 THEN 0 ELSE 11 - date_part('day', CURRENT_TIMESTAMP) END AS lookback),
history AS (SELECT CASE WHEN max(lookback.lookback) > 0 THEN sum(kwh) ELSE 0 END AS kwh FROM electricity_sums_hourly, lookback WHERE date >= (date_trunc('month', CURRENT_TIMESTAMP) - (lookback.lookback || ' days')::interval)::date AND date_part('month', date) = date_part('month', CURRENT_TIMESTAMP) - 1),
multiplier AS (SELECT CASE WHEN date_part('day', CURRENT_TIMESTAMP) > 20 THEN 3 WHEN date_part('day', CURRENT_TIMESTAMP) > 10 THEN 2 ELSE 1 END AS mult),
minuteh AS (SELECT round(((u.kwh * multiplier.mult + s.previous_year + history.kwh) / floor(multiplier.mult * elapsed_seconds.elapsed_seconds / 60 + days_in_month.days_in_month * 24 * 60 + lookback.lookback * 24 * 60) * days_in_month.days_in_month * 24 * 60)::numeric, 2) AS projected_use FROM electricity_usage_monthly u INNER JOIN electricity_statistics_monthly s ON u.month=s.month, days_in_month, elapsed_seconds, lookback, history, multiplier WHERE u.month = date_part('month', CURRENT_TIMESTAMP))
INSERT INTO prediction_test (time, day, hour, minute, minuteh) SELECT CURRENT_TIMESTAMP, day.projected_use, hour.projected_use, minute.projected_use, minuteh.projected_use FROM day, hour, minute, minuteh;