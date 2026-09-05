if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_count_plot_helpers.R', sep=''))

query <- "
    WITH bounds AS (
        SELECT
            DATE_TRUNC('year', MIN(cycle_start))::DATE AS first_year,
            DATE_TRUNC('year', CURRENT_DATE)::DATE AS current_year
        FROM
            water_statistics.water_cycles_view
    ), years AS (
        SELECT
            GENERATE_SERIES(first_year, current_year, INTERVAL '1 YEAR')::DATE AS year_start,
            current_year
        FROM
            bounds
        WHERE
            first_year IS NOT NULL
    )
    SELECT
        TO_CHAR(year_start, 'YYYY') AS label,
        COUNT(wc.*)::INTEGER AS cycles,
        CASE WHEN year_start = current_year THEN 'no' ELSE 'yes' END AS complete
    FROM
        years y
        LEFT JOIN water_statistics.water_cycles_view wc ON wc.cycle_start >= y.year_start
            AND wc.cycle_start < y.year_start + INTERVAL '1 YEAR'
    GROUP BY
        y.year_start,
        y.current_year
    ORDER BY
        y.year_start;
"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_count_yearly.png'
cycle_count_bar_plot(res, fname, "Well Pump Cycles by Year", "Year", "Cycles")

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
