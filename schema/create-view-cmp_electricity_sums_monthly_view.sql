CREATE OR REPLACE VIEW electricity_cmp.cmp_electricity_sums_monthly_view AS (
    SELECT
        date_part('year', start_date) AS year,
        date_part('month', start_date) AS month,
        sum(kwh) AS kwh,
        CASE
            WHEN
                CASE
                    WHEN DATE_PART('month', start_date) = 3 THEN COUNT(*) + 1
                    WHEN DATE_PART('month', start_date) = 11 THEN COUNT(*) - 1
                    ELSE COUNT(*)
                END / 24. = num_days(date_part('year', start_date)::INTEGER, date_part('month', start_date)::INTEGER) THEN 'yes'
            ELSE 'no'
        END AS complete
    FROM
        electricity_cmp.cmp_electricity_sums_hourly
    GROUP BY
        1, 2
    ORDER BY
        1, 2
);
