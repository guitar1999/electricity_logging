CREATE OR REPLACE VIEW electricity_plotting.electricity_hourly_dow_season AS (
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
            AND s.dow =
                CASE
                    WHEN u.hour > date_part('hour', CURRENT_TIMESTAMP) THEN date_part('dow', (CURRENT_TIMESTAMP - interval '1 day'))
                    ELSE date_part('dow', CURRENT_TIMESTAMP)
                END
            AND s.season =
                CASE
                    WHEN u.hour > date_part('hour', CURRENT_TIMESTAMP) THEN
                        (SELECT
                            season
                        FROM
                            meteorological_season
                        WHERE
                            doy = date_part('doy', (CURRENT_TIMESTAMP - interval '1 day'))
                        )
                    ELSE
                        (SELECT
                            season
                        FROM
                            meteorological_season
                        WHERE
                            doy = date_part('doy', CURRENT_TIMESTAMP)
                        )
                END
    GROUP BY
        u.sum_date,
        u.hour,
        u.kwh,
        u.complete
    ORDER BY
        u.sum_date,
        u.hour
);

