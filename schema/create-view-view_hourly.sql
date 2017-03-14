CREATE OR REPLACE VIEW electricity.view_hourly AS (
    (SELECT
        row_number() OVER (ORDER BY u.updated) AS row_number,
        u.hour AS label,
        COALESCE(u.kwh, 0) AS kwh,
        s.kwh_avg,
        u.complete
    FROM
        electricity.electricity_usage_hourly u
        INNER JOIN electricity_statistics.electricity_statistics_hourly_season s
            ON u.hour=s.hour
            AND s.season =
                CASE
                    WHEN u.hour > date_part('hour', CURRENT_TIMESTAMP) THEN (SELECT season FROM meteorological_season WHERE doy = date_part('doy', (CURRENT_TIMESTAMP - interval '1 day')))
                    ELSE (SELECT season FROM meteorological_season WHERE doy = date_part('doy', CURRENT_TIMESTAMP))
                END
    WHERE
        NOT u.hour = date_part('hour', CURRENT_TIMESTAMP)
    ORDER BY
        u.updated)
    UNION
    (SELECT
        24 AS row_number,
        date_part('hour', CURRENT_TIMESTAMP) AS label,
        u.kwh,
        s.kwh_avg,
        complete
    FROM
        electricity.electricity_usage_hourly u
        INNER JOIN electricity_statistics.electricity_statistics_hourly_season s
            ON u.hour=s.hour
    WHERE
        u.hour = date_part('hour', CURRENT_TIMESTAMP)
        AND s.season = (SELECT season FROM meteorological_season WHERE doy = date_part('doy', CURRENT_TIMESTAMP)))
);