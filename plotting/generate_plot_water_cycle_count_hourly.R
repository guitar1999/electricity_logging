if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_count_plot_helpers.R', sep=''))

query <- "
    WITH bounds AS (
        SELECT
            DATE_TRUNC('hour', CURRENT_TIMESTAMP) - INTERVAL '23 HOURS' AS start_hour,
            DATE_TRUNC('hour', CURRENT_TIMESTAMP) AS current_hour
    ), hours AS (
        SELECT
            GENERATE_SERIES(start_hour, current_hour, INTERVAL '1 HOUR') AS hour_start,
            current_hour
        FROM
            bounds
    )
    SELECT
        TO_CHAR(hour_start, 'HH24') AS label,
        COUNT(wc.*)::INTEGER AS cycles,
        CASE WHEN hour_start = current_hour THEN 'no' ELSE 'yes' END AS complete
    FROM
        hours h
        LEFT JOIN water_statistics.water_cycles_view wc ON wc.cycle_start >= h.hour_start
            AND wc.cycle_start < h.hour_start + INTERVAL '1 HOUR'
    GROUP BY
        h.hour_start,
        h.current_hour
    ORDER BY
        h.hour_start;
"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_count_hourly.png'
cycle_count_bar_plot(res, fname, "Well Pump Cycles in the Last 24 Hours", "Hour", "Cycles")

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
