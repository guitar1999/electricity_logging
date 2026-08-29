if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_plot_style.R', sep=''))

metrics_query <- "
    WITH cycles AS (
        SELECT
            cycle_start,
            cycle_end,
            runtime
        FROM
            water_statistics.water_cycles_view
        WHERE
            cycle_start >= TIMESTAMPTZ '2026-05-01'
            AND cycle_start < LEAST(CURRENT_TIMESTAMP, TIMESTAMPTZ '2026-08-30')
            AND runtime >= 0.5
    ), metrics AS (
        SELECT
            c.cycle_start,
            c.cycle_end,
            c.runtime,
            m.starting_watts,
            m.ending_watts,
            m.samples
        FROM
            cycles c
            CROSS JOIN LATERAL (
                WITH samples AS (
                    SELECT
                        measurement_time,
                        EXTRACT(EPOCH FROM measurement_time - c.cycle_start)::NUMERIC AS elapsed_seconds,
                        watts_water_pump * 2 AS watts
                    FROM
                        electricity_iotawatt.electricity_measurements
                    WHERE
                        measurement_time >= c.cycle_start
                        AND measurement_time < c.cycle_end
                        AND watts_water_pump > 10
                )
                SELECT
                    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY watts) FILTER (
                        WHERE elapsed_seconds >= 10
                        AND elapsed_seconds <= 30
                    ) AS starting_watts,
                    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY watts) FILTER (
                        WHERE elapsed_seconds >= GREATEST(0, c.runtime * 60 - 30)
                        AND elapsed_seconds <= GREATEST(0, c.runtime * 60 - 10)
                    ) AS ending_watts,
                    COUNT(*) AS samples
                FROM
                    samples
            ) m
        WHERE
            m.samples >= 4
    )
    SELECT
        cycle_start,
        runtime,
        100 * (starting_watts - ending_watts) / NULLIF(starting_watts, 0) AS percent_drop
    FROM
        metrics
    WHERE
        starting_watts IS NOT NULL
        AND ending_watts IS NOT NULL
    ORDER BY
        cycle_start;
"
res <- dbGetQuery(con, metrics_query)

fname <- '/tmp/water_cycle_runtime_power_drop.png'
rolling_median_n <- 25
res$runtime_rolling_median <- NA
res$drop_rolling_median <- NA
if (nrow(res) > 0) {
    for (i in 1:nrow(res)) {
        if (i >= rolling_median_n) {
            window <- (i - rolling_median_n + 1):i
            res$runtime_rolling_median[i] <- median(res$runtime[window], na.rm=TRUE)
            res$drop_rolling_median[i] <- median(res$percent_drop[window], na.rm=TRUE)
        }
    }
}

png(filename=fname, width=1200, height=620, units='px', pointsize=12, bg=cycle_bg)
layout(matrix(c(1, 2), nrow=2), heights=c(1, 1))

plot_metric <- function(values, trend, ylab, main, point_col, trend_col) {
    par(
        bg=cycle_bg,
        mar=c(4, 4.5, 3, 1.5),
        mgp=c(2.4, 0.7, 0),
        tcl=-0.25,
        col.axis=cycle_axis,
        col.lab=cycle_axis,
        col.main=cycle_text,
        fg=cycle_axis,
        bty='n',
        las=1
    )

    if (nrow(res) > 0) {
        xlim <- c(as.POSIXct('2026-05-01', tz='America/New_York'), min(Sys.time(), as.POSIXct('2026-08-30', tz='America/New_York')))
        ymin <- floor(min(values, trend, na.rm=TRUE))
        ymax <- ceiling(max(values, trend, na.rm=TRUE))
        if (ymin == ymax) {
            ymax <- ymin + 1
        }
        hseq <- seq(xlim[1], xlim[2], by='2 weeks')
        yseq <- pretty(c(ymin, ymax))

        cycle_draw_panel(xlim, range(yseq), "Cycle start date", ylab, main)
        cycle_grid_lines(h=yseq, v=hseq)
        axis(side=1, at=hseq, labels=format(hseq, '%b %d'), col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
        cycle_axis_y(yseq)
        points(res$cycle_start, values, col=adjustcolor(point_col, alpha.f=0.3), pch=19, cex=0.5)
        if (any(!is.na(trend))) {
            lines(res$cycle_start, trend, col=trend_col, lwd=2)
        }
        cycle_legend('topleft', legend=c('Cycle', paste(rolling_median_n, 'cycle rolling median', sep='-')), col=c(point_col, trend_col), pch=c(19, NA), lty=c(NA, 1), lwd=c(NA, 2), inset=0.01)
    } else {
        cycle_draw_panel(c(0, 1), c(0, 1), "Cycle start date", ylab, main)
        text(0.5, 0.5, 'No cycle metrics found', col=cycle_axis)
    }
}

plot_metric(
    res$runtime,
    res$runtime_rolling_median,
    "Runtime (minutes)",
    "Well Pump Cycle Runtime - May through August",
    cycle_blue,
    cycle_orange
)

plot_metric(
    res$percent_drop,
    res$drop_rolling_median,
    "Power drop: median 10-30s vs final 30-10s (%)",
    "Within-Cycle Power Drop - May through August",
    cycle_grey,
    cycle_red
)

dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
