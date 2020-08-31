CREATE OR REPLACE VIEW water_plotting.water_dow_plot_view AS (
    WITH u AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY sum_date DESC),
            sum_date,
            SUM(gallons) AS gallons,
            'yes'::TEXT AS complete
        FROM
            water_statistics.water_sums_hourly_view
        GROUP BY
            sum_date
        ORDER BY
            sum_date DESC
        LIMIT 7
        )
    SELECT
        INITCAP(TO_CHAR(u.sum_date, 'day')) AS label,
        u.gallons,
        SUM(s.gallons_avg * s.count) / SUM(s.count) AS gallons_avg,
        u.complete
    FROM
        u
        INNER JOIN water_statistics.water_statistics_dow_view s
            ON DATE_PART('dow', u.sum_date)=s.dow
    GROUP BY
        u.sum_date,
        u.gallons,
        u.complete
    ORDER BY
        u.sum_date
);