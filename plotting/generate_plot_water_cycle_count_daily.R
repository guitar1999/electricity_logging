if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_count_plot_helpers.R', sep=''))

query <- "
    WITH days AS (
        SELECT
            GENERATE_SERIES(CURRENT_DATE - INTERVAL '29 DAYS', CURRENT_DATE, INTERVAL '1 DAY')::DATE AS cycle_date
    )
    SELECT
        TO_CHAR(cycle_date, 'MM-DD') AS label,
        COUNT(wc.*)::INTEGER AS cycles,
        CASE WHEN cycle_date = CURRENT_DATE THEN 'no' ELSE 'yes' END AS complete
    FROM
        days d
        LEFT JOIN water_statistics.water_cycles_view wc ON wc.cycle_start >= d.cycle_date
            AND wc.cycle_start < d.cycle_date + INTERVAL '1 DAY'
    GROUP BY
        d.cycle_date
    ORDER BY
        d.cycle_date;
"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_count_daily.png'
cycle_count_bar_plot(res, fname, "Well Pump Cycles in the Last 30 Days", "", "Cycles", 2)

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
