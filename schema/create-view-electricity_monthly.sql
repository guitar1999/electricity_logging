CREATE OR REPLACE VIEW electricity_plotting.electricity_monthly AS (
    WITH u AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY MAX(sum_date) DESC),
            DATE_PART('month', sum_date) AS month,
            TO_CHAR(TO_TIMESTAMP(DATE_PART('month', sum_date)::text, 'MM'), 'Mon') AS month_text,
            SUM(kwh) AS kwh,
            CASE
                WHEN 'no' = ANY (array_agg(complete)) THEN 'no'
                ELSE 'yes'
            END AS complete
        FROM
            electricity_statistics.electricity_sums_hourly_best_available
        GROUP BY
            DATE_PART('month', sum_date),
            DATE_PART('year', sum_date)
        ORDER BY
            MAX(sum_date) DESC
        LIMIT 12
        )
    SELECT
        u.month_text AS label,
        u.kwh,
        SUM(s.kwh_avg * s.count) / SUM(s.count) AS kwh_avg,
        u.complete
    FROM
        u
        INNER JOIN electricity_cmp.cmp_electricity_statistics_monthly s
            ON u.month=s.month
    GROUP BY
        u.month_text,
        u.kwh,
        u.complete,
        u.row_number
    ORDER BY
        u.row_number DESC
);
