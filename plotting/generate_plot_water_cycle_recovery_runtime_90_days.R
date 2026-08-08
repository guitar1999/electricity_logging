if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_plot_style.R', sep=''))

query <- "
    WITH bounds AS (
        SELECT
            CURRENT_TIMESTAMP - INTERVAL '90 DAYS' AS start_time
    ), recent_cycles AS (
        SELECT
            wc.cycle_start,
            wc.cycle_end,
            wc.runtime
        FROM
            water_statistics.water_cycles_view wc,
            bounds b
        WHERE
            wc.cycle_start >= b.start_time - INTERVAL '2 DAYS'
    ), ordered AS (
        SELECT
            cycle_start,
            cycle_end,
            runtime,
            LAG(cycle_end) OVER (ORDER BY cycle_start) AS previous_cycle_end
        FROM
            recent_cycles
    )
    SELECT
        cycle_start,
        runtime,
        EXTRACT(EPOCH FROM cycle_start - previous_cycle_end)::NUMERIC / 60 AS recovery_minutes,
        TO_CHAR(cycle_start, 'Mon') AS month_label,
        DATE_TRUNC('month', cycle_start)::DATE AS month_start,
        CASE
            WHEN EXTRACT(EPOCH FROM cycle_start - previous_cycle_end)::NUMERIC / 60 < 30 THEN '<30 min'
            WHEN EXTRACT(EPOCH FROM cycle_start - previous_cycle_end)::NUMERIC / 60 < 120 THEN '30-120 min'
            WHEN EXTRACT(EPOCH FROM cycle_start - previous_cycle_end)::NUMERIC / 60 < 360 THEN '2-6 hr'
            ELSE '>6 hr'
        END AS recovery_bucket
    FROM
        ordered,
        bounds
    WHERE
        cycle_start >= bounds.start_time
        AND previous_cycle_end IS NOT NULL
        AND cycle_start >= previous_cycle_end
    ORDER BY
        cycle_start;
"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_recovery_runtime_90_days.png'
bucket_levels <- c('<30 min', '30-120 min', '2-6 hr', '>6 hr')
runtime_cap <- 6

month_colors <- c(
    'May'='#0f766e',
    'Jun'=cycle_blue,
    'Jul'=cycle_orange,
    'Aug'=cycle_red,
    'Sep'='#7c3aed',
    'Oct'='#0891b2',
    'Nov'='#be123c',
    'Dec'='#4d7c0f',
    'Jan'='#0369a1',
    'Feb'='#9333ea',
    'Mar'='#16a34a',
    'Apr'='#ca8a04'
)

summarize_bucket <- function(bucket) {
    runtime <- res$runtime[res$recovery_bucket == bucket]
    if (length(runtime) == 0) {
        return(c(n=0, median=NA, p75=NA, p95=NA))
    }
    c(
        n=length(runtime),
        median=median(runtime, na.rm=TRUE),
        p75=quantile(runtime, 0.75, na.rm=TRUE, names=FALSE),
        p95=quantile(runtime, 0.95, na.rm=TRUE, names=FALSE)
    )
}
bucket_summary <- t(sapply(bucket_levels, summarize_bucket))

long_res <- res[res$recovery_bucket == '>6 hr',]
months <- sort(unique(res$month_start))
long_summary <- data.frame(
    month_start=months,
    month_label=format(as.Date(months), '%b'),
    n=rep(0, length(months)),
    median=rep(NA, length(months)),
    p75=rep(NA, length(months))
)
if (nrow(long_summary) > 0) {
    for (i in 1:nrow(long_summary)) {
        runtime <- long_res$runtime[long_res$month_start == long_summary$month_start[i]]
        if (length(runtime) > 0) {
            long_summary$n[i] <- length(runtime)
            long_summary$median[i] <- median(runtime, na.rm=TRUE)
            long_summary$p75[i] <- quantile(runtime, 0.75, na.rm=TRUE, names=FALSE)
        }
    }
}

png(filename=fname, width=1200, height=620, units='px', pointsize=12, bg=cycle_bg)
layout(matrix(c(1, 2, 1, 3), nrow=2, byrow=TRUE), widths=c(2.25, 1.25), heights=c(1, 1))

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

if (nrow(res) > 0) {
    recovery_hours <- res$recovery_minutes / 60
    max_recovery <- max(6, ceiling(max(recovery_hours, na.rm=TRUE)))
    plot_runtime <- pmin(res$runtime, runtime_cap)
    point_pch <- ifelse(res$runtime > runtime_cap, 17, 19)
    raw_point_colors <- month_colors[res$month_label]
    raw_point_colors[is.na(raw_point_colors)] <- cycle_grey
    point_colors <- adjustcolor(raw_point_colors, alpha.f=0.65)

    cycle_draw_panel(c(0, max_recovery), c(0, runtime_cap), "Recovery interval (hours)", "Following runtime (minutes)", "Well Pump Recovery vs Runtime - Last 90 Days")
    cycle_grid_lines(h=seq(0, runtime_cap, 1), v=c(0.5, 2, 6, seq(0, max_recovery, 2)))
    axis(side=1, at=seq(0, max_recovery, 2), labels=seq(0, max_recovery, 2), col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
    cycle_axis_y(seq(0, runtime_cap, 1))
    abline(v=c(0.5, 2, 6), col=cycle_axis, lty=2)
    points(recovery_hours, plot_runtime, col=point_colors, pch=point_pch, cex=0.8)

    legend_months <- names(month_colors)[names(month_colors) %in% unique(res$month_label)]
    cycle_legend('topright', legend=legend_months, col=month_colors[legend_months], pch=19, inset=0.01)
    if (any(res$runtime > runtime_cap)) {
        text(max_recovery, runtime_cap, labels='triangles: >6 min', pos=2, cex=0.75, col=cycle_axis)
    }
} else {
    cycle_draw_panel(c(0, 1), c(0, runtime_cap), "Recovery interval (hours)", "Following runtime (minutes)", "Well Pump Recovery vs Runtime - Last 90 Days")
    text(0.5, runtime_cap / 2, 'No cycles found', col=cycle_axis)
}

par(mar=c(1.5, 1, 4, 1))
plot(c(0, 1), c(0, 1), type='n', axes=FALSE, xlab='', ylab='', main='Runtime by Recovery Bucket')
rect(0, 0, 1, 1, col=cycle_panel, border=NA)
text(0.02, 0.88, 'Bucket', adj=0, font=2, col=cycle_text)
text(0.45, 0.88, 'n', adj=1, font=2, col=cycle_text)
text(0.62, 0.88, 'Med', adj=1, font=2, col=cycle_text)
text(0.78, 0.88, 'P75', adj=1, font=2, col=cycle_text)
text(0.95, 0.88, 'P95', adj=1, font=2, col=cycle_text)
for (i in seq_along(bucket_levels)) {
    y <- 0.88 - i * 0.17
    text(0.02, y, bucket_levels[i], adj=0, col=cycle_axis)
    text(0.45, y, bucket_summary[i, 'n'], adj=1, col=cycle_axis)
    text(0.62, y, ifelse(is.na(bucket_summary[i, 'median']), '-', sprintf('%.2f', bucket_summary[i, 'median'])), adj=1, col=cycle_axis)
    text(0.78, y, ifelse(is.na(bucket_summary[i, 'p75']), '-', sprintf('%.2f', bucket_summary[i, 'p75'])), adj=1, col=cycle_axis)
    text(0.95, y, ifelse(is.na(bucket_summary[i, 'p95']), '-', sprintf('%.2f', bucket_summary[i, 'p95'])), adj=1, col=cycle_axis)
}
mtext('Minutes', side=1, line=0.4, cex=0.8, col=cycle_axis)

par(mar=c(4, 4, 3, 1))
if (nrow(long_summary) > 0 && any(!is.na(long_summary$median))) {
    x <- seq_len(nrow(long_summary))
    ytop <- max(2, long_summary$p75, long_summary$median, na.rm=TRUE)
    cycle_draw_panel(c(0.5, length(x) + 0.5), c(0, ceiling(ytop)), "Month", "Minutes", ">6 hr Recovery Runtime Trend")
    cycle_grid_lines(h=seq(0, ceiling(ytop), 0.5))
    axis(side=1, at=x, labels=long_summary$month_label, col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
    cycle_axis_y(seq(0, ceiling(ytop), 0.5))
    lines(x, long_summary$median, col=cycle_blue, lwd=2)
    points(x, long_summary$median, col=cycle_blue, pch=19)
    segments(x, long_summary$median, x, long_summary$p75, col=cycle_blue_light, lwd=2)
    text(x, pmin(ceiling(ytop), long_summary$p75 + 0.15), labels=paste('n=', long_summary$n, sep=''), cex=0.75, col=cycle_axis)
} else {
    cycle_draw_panel(c(0, 1), c(0, 1), "Month", "Minutes", ">6 hr Recovery Runtime Trend")
    text(0.5, 0.5, 'No >6 hr recovery cycles', col=cycle_axis)
}

dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
