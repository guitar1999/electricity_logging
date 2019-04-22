CREATE OR REPLACE VIEW electricity_statistics.electricity_sums_hourly_best_available AS (
    SELECT
        COALESCE(cmp.sum_date, pi.sum_date, c.sum_date) AS sum_date,
        COALESCE(cmp.hour, pi.hour, c.hour) AS hour,
        CASE
            WHEN COALESCE(cmp.sum_date, pi.sum_date, c.sum_date) > '2018-11-03' -- electrician wired generator this day and measurements seem closer to correct, so we won't model until we have enough data to build a new model. we'll take this out then.
            THEN COALESCE(cmp.kwh, pi.kwh, c.kwh, 0)
            ELSE COALESCE(cmp.kwh, pi.kwh_modeled, pi.kwh, c.kwh, 0)
        END AS kwh,
        CASE
            WHEN NOT cmp.kwh IS NULL THEN 'yes'::TEXT
            ELSE 'no'::TEXT
        END AS complete
    FROM
        electricity_cmp.cmp_electricity_sums_hourly_view cmp
        FULL OUTER JOIN electricity_statistics.electricity_sums_hourly pi
            ON cmp.sum_date=pi.sum_date AND cmp.hour=pi.hour
        FULL OUTER JOIN (
            SELECT
                CURRENT_DATE AS sum_date,
                DATE_PART('hour', CURRENT_TIMESTAMP) AS hour,
                SUM((watts_ch1 + watts_ch2) * tdiff / 1000. / 60 / 60) AS kwh,
                'no'::TEXT AS complete
            FROM
                electricity.electricity_measurements
            WHERE
                measurement_time >= CURRENT_DATE
                AND DATE_PART('hour', measurement_time) = DATE_PART('hour', CURRENT_TIMESTAMP)
            ) AS c
            ON cmp.sum_date=c.sum_date AND cmp.hour=c.hour
    ORDER BY
        1,
        2
);
