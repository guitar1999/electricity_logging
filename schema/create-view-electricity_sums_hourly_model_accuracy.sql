CREATE VIEW electricity_statistics.electricity_sums_hourly_model_accuracy AS (
    SELECT
        s.sum_date,
        s.hour,
        c.kwh AS cmp_kwh,
        s.kwh_modeled AS modeled_kwh,
        s.kwh_modeled - c.kwh AS difference
    FROM
        electricity_statistics.electricity_sums_hourly s
        INNER JOIN electricity_cmp.cmp_electricity_sums_hourly_view c
            ON s.sum_date=c.sum_date
            AND s.hour=c.hour
    ORDER BY
        s.sum_date,
        s.hour
);
