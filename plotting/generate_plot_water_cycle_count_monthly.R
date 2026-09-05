if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_count_plot_helpers.R', sep=''))

query <- "
    WITH bounds AS (
        SELECT DATE_TRUNC('month', CURRENT_DATE)::DATE AS current_month
    ), months AS (
        SELECT
            GENERATE_SERIES(current_month - INTERVAL '11 MONTHS', current_month, INTERVAL '1 MONTH')::DATE AS month_start,
            current_month
        FROM
            bounds
    )
    SELECT
        TO_CHAR(month_start, 'Mon') AS label,
        COUNT(wc.*)::INTEGER AS cycles,
        CASE WHEN month_start = current_month THEN 'no' ELSE 'yes' END AS complete
    FROM
        months m
        LEFT JOIN water_statistics.water_cycles_view wc ON wc.cycle_start >= m.month_start
            AND wc.cycle_start < m.month_start + INTERVAL '1 MONTH'
    GROUP BY
        m.month_start,
        m.current_month
    ORDER BY
        m.month_start;
"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_count_monthly.png'
cycle_count_bar_plot(res, fname, "Well Pump Cycles in the Last 12 Months", "Month", "Cycles")

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
