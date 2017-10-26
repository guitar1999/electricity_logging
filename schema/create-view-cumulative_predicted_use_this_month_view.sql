CREATE OR REPLACE VIEW electricity_plotting.cumulative_predicted_use_this_month_view AS (
    WITH hour_stats AS (
        SELECT 
            season,
            hour,
            sum(kwh_avg * count) / sum(count) AS kwh_avg
        FROM
            electricity_cmp.cmp_electricity_statistics_hourly 
        GROUP BY
            season,
            hour
        ), recent_stats AS (
        SELECT
            m.season,
            c.hour,
            sum(c.kwh) / count(*) AS kwh_avg
        FROM
            electricity_cmp.cmp_electricity_sums_hourly_view c
            INNER JOIN weather_data.meteorological_season m ON DATE_PART('DOY', c.sum_date)=m.doy
        WHERE 
            c.sum_date > CURRENT_TIMESTAMP - INTERVAL '1 MONTH'
        GROUP BY 
            m.season,
            c.hour
        ), bias AS (
        SELECT
            s.season,
            s.hour,
            COALESCE(r.kwh_avg - s.kwh_avg, 0) AS kwh_bias
        FROM
            hour_stats s
            LEFT JOIN recent_stats r ON s.season=r.season AND s.hour=r.hour
        ), month_to_date AS (
        SELECT
            sum_date, 
            hour,
            SUM(kwh) OVER (ORDER BY sum_date, hour) AS cumulative_kwh
        FROM 
            electricity_statistics.electricity_sums_hourly_best_available
        WHERE
            DATE_PART('YEAR', CURRENT_TIMESTAMP) = DATE_PART('YEAR', sum_date)
            AND DATE_PART('MONTH', CURRENT_TIMESTAMP) = DATE_PART('MONTH', sum_date)
        ), mtd_max AS (
        SELECT
            MAX((sum_date::TEXT || ' ' || hour::TEXT || ':00:00')::TIMESTAMP WITH TIME ZONE) AS end_time,
            MAX(cumulative_kwh) AS end_kwh
        FROM 
            month_to_date
        ), predict_hours AS (
            SELECT
                generate_series AS timestamp
            FROM
                mtd_max m, 
                generate_series(m.end_time + INTERVAL '1 HOUR', DATE_TRUNC('MONTH', CURRENT_TIMESTAMP + INTERVAL '1 MONTH') - INTERVAL '1 HOUR', INTERVAL '1 HOUR')
                
        ), predicted_use AS (
            SELECT
                p.timestamp,
                h.kwh_avg + b.kwh_bias AS kwh
            FROM
                predict_hours p
                LEFT JOIN weather_data.meteorological_season m ON DATE_PART('DOY', p.timestamp) = m.doy
                LEFT JOIN hour_stats h ON DATE_PART('HOUR', p.timestamp) = h.hour
                    AND m.season=h.season
                LEFT JOIN bias b ON h.season=b.season AND h.hour=b.hour
        )
        SELECT
            p.timestamp,
            m.end_kwh + SUM(p.kwh) OVER (ORDER BY timestamp) AS cumulative_kwh
        FROM
            predicted_use p,
            mtd_max m
        ORDER BY 
            p.timestamp
);


