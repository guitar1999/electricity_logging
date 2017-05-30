CREATE OR REPLACE VIEW electricity_plotting.electricity_hourly AS (
    WITH u AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY sum_date DESC, hour DESC),
            sum_date,
            hour,
            kwh,
            complete
        FROM
            electricity_statistics.electricity_sums_hourly_best_available
        ORDER BY
            sum_date DESC,
            hour DESC
        LIMIT 24
        )
    SELECT
        u.hour AS label,
        u.kwh,
        SUM(s.kwh_avg * s.count) / SUM(s.count) AS kwh_avg,
        u.complete
    FROM
        u
        INNER JOIN electricity_cmp.cmp_electricity_statistics_hourly s
            ON u.hour=s.hour
    GROUP BY
        u.sum_date,
        u.hour,
        u.kwh,
        u.complete
    ORDER BY
        u.sum_date,
        u.hour
);
