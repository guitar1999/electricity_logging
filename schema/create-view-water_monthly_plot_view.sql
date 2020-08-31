CREATE OR REPLACE VIEW water_plotting.water_monthly_plot_view AS (
    WITH u AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY MAX(sum_date) DESC),
            DATE_PART('month', sum_date) AS month,
            TO_CHAR(TO_TIMESTAMP(DATE_PART('month', sum_date)::text, 'MM'), 'Mon') AS month_text,
            SUM(gallons) AS gallons,
            'yes'::TEXT AS complete
        FROM
            water_statistics.water_sums_hourly_view
        GROUP BY
            DATE_PART('month', sum_date),
            DATE_PART('year', sum_date)
        ORDER BY
            MAX(sum_date) DESC
        LIMIT 12
        )
    SELECT
        u.month_text AS label,
        u.gallons,
        SUM(s.gallons_avg * s.count) / SUM(s.count) AS gallons_avg,
        u.complete
    FROM
        u
        LEFT JOIN water_statistics.water_statistics_monthly_view s
            ON u.month=s.month
    GROUP BY
        u.month_text,
        u.gallons,
        u.complete,
        u.row_number
    ORDER BY
        u.row_number DESC
);
