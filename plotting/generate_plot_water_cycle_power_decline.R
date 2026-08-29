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
            m.slope_watts_per_second,
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
                    REGR_SLOPE(watts, elapsed_seconds) AS slope_watts_per_second,
                    COUNT(*) AS samples
                FROM
                    samples
            ) m
        WHERE
            m.samples >= 4
    )
    SELECT
        cycle_start,
        cycle_end,
        runtime,
        starting_watts,
        ending_watts,
        starting_watts - ending_watts AS absolute_drop_watts,
        100 * (starting_watts - ending_watts) / NULLIF(starting_watts, 0) AS percent_drop,
        slope_watts_per_second,
        samples,
        CASE
            WHEN cycle_start >= TIMESTAMPTZ '2026-08-29' AND cycle_start < TIMESTAMPTZ '2026-08-30' THEN 'Aug 29'
            WHEN cycle_start >= TIMESTAMPTZ '2026-08-01' AND cycle_start < TIMESTAMPTZ '2026-08-15' THEN 'Early Aug'
            WHEN cycle_start >= TIMESTAMPTZ '2026-07-01' AND cycle_start < TIMESTAMPTZ '2026-08-01' THEN 'July'
            WHEN cycle_start >= TIMESTAMPTZ '2026-06-01' AND cycle_start < TIMESTAMPTZ '2026-07-01' THEN 'June'
            WHEN cycle_start >= TIMESTAMPTZ '2026-05-01' AND cycle_start < TIMESTAMPTZ '2026-06-01' THEN 'May'
            ELSE NULL
        END AS analysis_period
    FROM
        metrics
    WHERE
        starting_watts IS NOT NULL
        AND ending_watts IS NOT NULL
    ORDER BY
        cycle_start;
"
metrics <- dbGetQuery(con, metrics_query)

fname <- '/tmp/water_cycle_power_decline.png'
metrics_fname <- '/tmp/water_cycle_power_decline_metrics.csv'
write.csv(metrics, metrics_fname, row.names=FALSE)

period_levels <- c('May', 'June', 'July', 'Early Aug', 'Aug 29')
period_colors <- c(
    'May'='#0f766e',
    'June'=cycle_blue,
    'July'=cycle_orange,
    'Early Aug'='#7c3aed',
    'Aug 29'=cycle_red
)

representative_cycles <- data.frame()
if (nrow(metrics) > 0) {
    for (period in period_levels) {
        period_rows <- metrics[metrics$analysis_period == period & !is.na(metrics$percent_drop),]
        if (nrow(period_rows) > 0) {
            target_drop <- median(period_rows$percent_drop, na.rm=TRUE)
            representative_cycles <- rbind(
                representative_cycles,
                period_rows[which.min(abs(period_rows$percent_drop - target_drop)),]
            )
        }
    }
}

curves <- data.frame()
if (nrow(representative_cycles) > 0) {
    for (i in 1:nrow(representative_cycles)) {
        cycle_start <- strftime(representative_cycles$cycle_start[i], format='%Y-%m-%d %H:%M:%S%z')
        cycle_end <- strftime(representative_cycles$cycle_end[i], format='%Y-%m-%d %H:%M:%S%z')
        curve_query <- sprintf(
            "SELECT EXTRACT(EPOCH FROM measurement_time - TIMESTAMPTZ %s)::NUMERIC AS elapsed_seconds, watts_water_pump * 2 AS watts FROM electricity_iotawatt.electricity_measurements WHERE measurement_time >= TIMESTAMPTZ %s AND measurement_time < TIMESTAMPTZ %s AND watts_water_pump > 10 ORDER BY measurement_time;",
            dbQuoteString(con, cycle_start),
            dbQuoteString(con, cycle_start),
            dbQuoteString(con, cycle_end)
        )
        curve <- dbGetQuery(con, curve_query)
        if (nrow(curve) > 0) {
            curve$analysis_period <- representative_cycles$analysis_period[i]
            curve$cycle_start <- representative_cycles$cycle_start[i]
            curves <- rbind(curves, curve)
        }
    }
}

rolling_median_n <- 25
metrics$rolling_percent_drop <- NA
if (nrow(metrics) > 0) {
    for (i in 1:nrow(metrics)) {
        if (i >= rolling_median_n) {
            metrics$rolling_percent_drop[i] <- median(metrics$percent_drop[(i - rolling_median_n + 1):i], na.rm=TRUE)
        }
    }
}

png(filename=fname, width=1200, height=720, units='px', pointsize=12, bg=cycle_bg)
layout(matrix(c(1, 2), nrow=2), heights=c(1, 1))

par(
    bg=cycle_bg,
    mar=c(4, 4.5, 4, 1.5),
    mgp=c(2.4, 0.7, 0),
    tcl=-0.25,
    col.axis=cycle_axis,
    col.lab=cycle_axis,
    col.main=cycle_text,
    fg=cycle_axis,
    bty='n',
    las=1
)

if (nrow(curves) > 0) {
    xmax <- max(60, ceiling(max(curves$elapsed_seconds, na.rm=TRUE) / 30) * 30)
    ymin <- floor(min(curves$watts, na.rm=TRUE) / 100) * 100
    ymax <- ceiling(max(curves$watts, na.rm=TRUE) / 100) * 100
    cycle_draw_panel(c(0, xmax), c(ymin, ymax), "Seconds since pump start", "Watts", "Representative Within-Cycle Pump Power Curves")
    cycle_grid_lines(h=pretty(c(ymin, ymax)), v=seq(0, xmax, 30))
    axis(side=1, at=seq(0, xmax, 30), labels=seq(0, xmax, 30), col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
    cycle_axis_y(pretty(c(ymin, ymax)))
    for (period in period_levels) {
        curve <- curves[curves$analysis_period == period,]
        if (nrow(curve) > 0) {
            lines(curve$elapsed_seconds, curve$watts, col=period_colors[period], lwd=2)
        }
    }
    legend_periods <- period_levels[period_levels %in% unique(curves$analysis_period)]
    cycle_legend('topright', legend=legend_periods, col=period_colors[legend_periods], lty=1, lwd=2, inset=0.01)
} else {
    cycle_draw_panel(c(0, 60), c(0, 1), "Seconds since pump start", "Watts", "Representative Within-Cycle Pump Power Curves")
    text(30, 0.5, 'No representative cycles found', col=cycle_axis)
}

par(
    bg=cycle_bg,
    mar=c(4, 4.5, 4, 1.5),
    mgp=c(2.4, 0.7, 0),
    tcl=-0.25,
    col.axis=cycle_axis,
    col.lab=cycle_axis,
    col.main=cycle_text,
    fg=cycle_axis,
    bty='n',
    las=1
)

if (nrow(metrics) > 0) {
    xlim <- range(metrics$cycle_start, na.rm=TRUE)
    ymin <- floor(min(metrics$percent_drop, na.rm=TRUE) / 5) * 5
    ymax <- ceiling(max(metrics$percent_drop, metrics$rolling_percent_drop, na.rm=TRUE) / 5) * 5
    hseq <- seq(as.POSIXct('2026-05-01', tz='America/New_York'), as.POSIXct('2026-08-30', tz='America/New_York'), by='2 weeks')
    raw_colors <- period_colors[metrics$analysis_period]
    raw_colors[is.na(raw_colors)] <- cycle_grey
    cycle_draw_panel(xlim, c(ymin, ymax), "Cycle start date", "Power drop: median 10-30s vs final 30-10s (%)", "Within-Cycle Power Drop Trend")
    cycle_grid_lines(h=pretty(c(ymin, ymax)), v=hseq)
    axis(side=1, at=hseq, labels=format(hseq, '%b %d'), col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
    cycle_axis_y(pretty(c(ymin, ymax)))
    points(metrics$cycle_start, metrics$percent_drop, col=adjustcolor(raw_colors, alpha.f=0.35), pch=19, cex=0.55)
    if (any(!is.na(metrics$rolling_percent_drop))) {
        lines(metrics$cycle_start, metrics$rolling_percent_drop, col=cycle_red, lwd=2)
    }
    cycle_legend('topleft', legend=c('Cycle drop', '25-cycle rolling median'), col=c(cycle_blue, cycle_red), pch=c(19, NA), lty=c(NA, 1), lwd=c(NA, 2), inset=0.01)
} else {
    cycle_draw_panel(c(0, 1), c(0, 1), "Cycle start date", "Power drop (%)", "Within-Cycle Power Drop Trend")
    text(0.5, 0.5, 'No cycle metrics found', col=cycle_axis)
}

dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
system(paste("scp", metrics_fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
