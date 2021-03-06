CREATE OR REPLACE VIEW water_plotting.water_hourly_dow_plot_view AS (
    WITH u AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY sum_date DESC, hour DESC),
            sum_date,
            hour,
            gallons,
            'yes'::TEXT AS complete
        FROM
            water_statistics.water_sums_hourly_view
        ORDER BY
            sum_date DESC,
            hour DESC
        LIMIT 24
        )
    SELECT
        u.hour AS label,
        u.gallons,
        SUM(s.gallons_avg * s.count) / SUM(s.count) AS gallons_avg,
        u.complete
    FROM
        u
        INNER JOIN water_statistics.water_statistics_hourly_view s
            ON u.hour=s.hour
            AND s.dow =
                CASE
                    WHEN u.hour > date_part('hour', CURRENT_TIMESTAMP) THEN date_part('dow', (CURRENT_TIMESTAMP - interval '1 day'))
                    ELSE date_part('dow', CURRENT_TIMESTAMP)
                END
    GROUP BY
        u.sum_date,
        u.hour,
        u.gallons,
        u.complete
    ORDER BY
        u.sum_date,
        u.hour
);
