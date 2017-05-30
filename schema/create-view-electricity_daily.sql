CREATE OR REPLACE VIEW electricity_plotting.electricity_daily AS (
    WITH u AS (
        SELECT
            ROW_NUMBER() OVER (ORDER BY sum_date DESC),
            sum_date,
            SUM(kwh) AS kwh,
            CASE WHEN 'no' = ANY (array_agg(complete)) THEN 'no' ELSE 'yes' END AS complete
        FROM
            electricity_statistics.electricity_sums_hourly_best_available
        GROUP BY
            sum_date
        ORDER BY
            sum_date DESC
        )
    SELECT
        u.sum_date,
        CONCAT_WS(' -', TO_CHAR(TO_TIMESTAMP(DATE_PART('month', u.sum_date)::text, 'MM'), 'Mon'), TO_CHAR(DATE_PART('day', u.sum_date), '09')) AS label,
        u.kwh,
        u1.kwh AS previous_year,
        u.complete,
        u.row_number
    FROM
        u
        LEFT JOIN u u1
            ON u.sum_date - INTERVAL '1 year' = u1.sum_date
    ORDER BY
        u.sum_date
);
