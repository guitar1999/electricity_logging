CREATE OR REPLACE VIEW electricity_plotting.electricity_dow_season AS (
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
        LIMIT 7
        )
    SELECT
        INITCAP(TO_CHAR(u.sum_date, 'day')) AS label,
        u.kwh,
        SUM(s.kwh_avg * s.count) / SUM(s.count) AS kwh_avg,
        u.complete
    FROM
        u
        INNER JOIN electricity_cmp.cmp_electricity_statistics_dow s
            ON DATE_PART('dow', u.sum_date)=s.dow
            AND s.season =
                (SELECT
                    season
                FROM
                    meteorological_season
                WHERE
                    doy = DATE_PART('doy', u.sum_date)
                )
    GROUP BY
        u.sum_date,
        u.kwh,
        u.complete
    ORDER BY
        u.sum_date
);