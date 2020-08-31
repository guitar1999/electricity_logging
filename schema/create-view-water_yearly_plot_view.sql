CREATE OR REPLACE VIEW water_plotting.water_yearly_plot_view AS (
    WITH u AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY DATE_PART('year', sum_date) DESC),
            DATE_PART('year', sum_date) AS year,
            SUM(gallons) AS gallons,
            'yes'::TEXT AS complete
        FROM
            water_statistics.water_sums_hourly_view
        GROUP BY
            DATE_PART('year', sum_date)
        ORDER BY
            DATE_PART('year', sum_date) DESC
        ),
    pytd AS (
        SELECT
            DATE_PART('year', CURRENT_DATE) AS year,
            SUM(gallons) +
                CASE
                    WHEN DATE_PART('year', CURRENT_DATE) - 1 = 2016 THEN 46048.72230754999999996671
                    ELSE 0
                END AS gallons
        FROM
            water_statistics.water_sums_hourly_view
        WHERE
            DATE_PART('year', sum_date) = DATE_PART('year', CURRENT_DATE) - 1
            AND sum_date <= CURRENT_DATE - INTERVAL '1 year'
         )
    SELECT
        u.year AS label,
        u.gallons,
        pytd.gallons AS previous_yeartodate_gallons,
        u.complete
    FROM
        u
        LEFT JOIN pytd
            ON u.year=pytd.year
    ORDER BY
        u.year
);
