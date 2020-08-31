CREATE OR REPLACE VIEW electricity.view_hourly AS (
    SELECT
        row_number() OVER (ORDER BY u.updated) AS row_number,
        u.hour AS label,
        COALESCE(u.kwh, 0) AS kwh,
        s.kwh_avg,
        ss.kwh_avg AS kwh_avg_season,
        sd.kwh_avg AS kwh_avg_dow,
        sds.kwh_avg AS kwh_avg_dow_season,
        u.complete
    FROM
        electricity_usage_hourly u
        INNER JOIN electricity_statistics_hourly s
            ON u.hour=s.hour
        INNER JOIN electricity_statistics.electricity_statistics_hourly_season ss
            ON u.hour=ss.hour
            AND ss.season =
                CASE
                    WHEN u.hour > date_part('hour', CURRENT_TIMESTAMP) THEN (SELECT season FROM meteorological_season WHERE doy = date_part('doy', (CURRENT_TIMESTAMP - interval '1 day')))
                    ELSE (SELECT season FROM meteorological_season WHERE doy = date_part('doy', CURRENT_TIMESTAMP))
                END
        INNER JOIN electricity_statistics.electricity_statistics_hourly_dow sd
            ON u.hour=sd.hour
            AND sd.dow =
                CASE
                    WHEN u.hour > date_part('hour', CURRENT_TIMESTAMP) THEN date_part('dow', (CURRENT_TIMESTAMP - interval '1 day'))
                    ELSE date_part('dow', CURRENT_TIMESTAMP)
                END
        INNER JOIN electricity_statistics.electricity_statistics_hourly_dow_season sds
            ON u.hour=sds.hour
            AND sds.dow = sd.dow
            AND sds.season = ss.season
    ORDER BY
        u.updated
);
