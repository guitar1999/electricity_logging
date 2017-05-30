CREATE OR REPLACE VIEW electricity_plotting.electricity_yearly AS (
    WITH u AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY DATE_PART('year', sum_date) DESC),
            DATE_PART('year', sum_date) AS year,
            SUM(kwh) AS kwh,
            CASE
                WHEN 'no' = ANY (array_agg(complete)) THEN 'no'
                ELSE 'yes'
            END AS complete
        FROM
            electricity_statistics.electricity_sums_hourly_best_available
        GROUP BY
            DATE_PART('year', sum_date)
        ORDER BY
            DATE_PART('year', sum_date) DESC
        ),
    pytd AS (
        SELECT
            DATE_PART('year', CURRENT_DATE) AS year,
            SUM(kwh) +
                CASE
                    WHEN DATE_PART('year', CURRENT_DATE) - 1 = 2016 THEN 1706.874
                    ELSE 0
                END AS kwh
        FROM
            electricity_statistics.electricity_sums_hourly_best_available
        WHERE
            DATE_PART('year', sum_date) = DATE_PART('year', CURRENT_DATE) - 1
            AND sum_date <= CURRENT_DATE - INTERVAL '1 year'
         )
    SELECT
        u.year AS label,
        u.kwh,
        pytd.kwh AS previous_yeartodate_kwh,
        u.complete
    FROM
        u
        LEFT JOIN pytd
            ON u.year=pytd.year
    ORDER BY
        u.year
);
