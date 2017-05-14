CREATE OR REPLACE VIEW electricity_plotting.electricity_hourly_season AS (
    WITH u AS (
        (SELECT
            e.sum_date, e.hour,
            COALESCE(c.kwh, COALESCE(e.kwh_modeled, e.kwh)) AS kwh
        FROM
            electricity_statistics.electricity_sums_hourly e
            LEFT JOIN electricity_cmp.cmp_electricity_sums_hourly_view c
                ON e.sum_date=c.sum_date
                AND e.hour=c.hour
        ORDER BY
            e.sum_date DESC,
            e.hour DESC
        LIMIT 23)
        UNION
        (SELECT
            CURRENT_TIMESTAMP::DATE AS sum_date,
            date_part('hour', CURRENT_TIMESTAMP) AS label,
            increment_usage('electricity_usage_hourly', 'hour') AS kwh
        ))
    SELECT
        u.sum_date,
        u.hour AS label,
        u.kwh,
        SUM(s.kwh_avg * s.count) / SUM(s.count) AS kwh_avg
    FROM
        u
        INNER JOIN electricity_cmp.cmp_electricity_statistics_hourly s
            ON u.hour=s.hour
            AND s.season = (
                SELECT
                    season
                FROM
                    meteorological_season
                WHERE
                    doy = date_part('doy', sum_date)
                )
    GROUP BY
        u.sum_date,
        u.hour,
        u.kwh
    ORDER BY
        u.sum_date,
        u.hour
);
