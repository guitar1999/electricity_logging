if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_plot_style.R', sep=''))

metrics_query <- "
    WITH cycle_base AS (
        SELECT
            cycle_start,
            cycle_end,
            runtime,
            LAG(cycle_end) OVER (ORDER BY cycle_start) AS previous_cycle_end
        FROM
            water_statistics.water_cycles_view
        WHERE
            cycle_start >= TIMESTAMPTZ '2026-04-29'
            AND cycle_start < LEAST(CURRENT_TIMESTAMP, TIMESTAMPTZ '2026-08-30')
    ), cycles AS (
        SELECT
            cycle_start,
            cycle_end,
            runtime,
            EXTRACT(EPOCH FROM cycle_start - previous_cycle_end)::NUMERIC / 60 AS recovery_minutes
        FROM
            cycle_base
        WHERE
            cycle_start >= TIMESTAMPTZ '2026-05-01'
            AND previous_cycle_end IS NOT NULL
            AND cycle_start >= previous_cycle_end
            AND runtime >= 0.5
    ), metrics AS (
        SELECT
            c.cycle_start,
            c.cycle_end,
            c.runtime,
            c.recovery_minutes,
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
        recovery_minutes,
        100 * (starting_watts - ending_watts) / NULLIF(starting_watts, 0) AS percent_drop,
        TO_CHAR(cycle_start, 'Mon') AS month_label
    FROM
        metrics
    WHERE
        starting_watts IS NOT NULL
        AND ending_watts IS NOT NULL
    ORDER BY
        cycle_start;
"
cycles <- dbGetQuery(con, metrics_query)

fname <- '/tmp/water_cycle_runtime_power_drop.png'
summary_fname <- '/tmp/water_cycle_runtime_power_drop_summary.csv'
correlation_fname <- '/tmp/water_cycle_runtime_power_drop_correlations.csv'

month_colors <- c(
    'May'='#0f766e',
    'Jun'=cycle_blue,
    'Jul'=cycle_orange,
    'Aug'=cycle_red
)

cycles$next5_runtime_median <- NA
if (nrow(cycles) > 1) {
    for (i in 1:nrow(cycles)) {
        first_next <- i + 1
        last_next <- min(nrow(cycles), i + 5)
        if (first_next <= last_next) {
            cycles$next5_runtime_median[i] <- median(cycles$runtime[first_next:last_next], na.rm=TRUE)
        }
    }
}

spearman_value <- function(data, xcol, ycol) {
    data <- data[!is.na(data[[xcol]]) & !is.na(data[[ycol]]),]
    if (nrow(data) < 3) {
        return(NA)
    }
    suppressWarnings(cor(data[[xcol]], data[[ycol]], method='spearman'))
}

spearman_label <- function(data, xcol, ycol) {
    data <- data[!is.na(data[[xcol]]) & !is.na(data[[ycol]]),]
    if (nrow(data) < 3) {
        return('Spearman rho: n/a')
    }
    sprintf('Spearman rho: %.2f (n=%s)', spearman_value(data, xcol, ycol), format(nrow(data), big.mark=','))
}

partial_spearman <- function(data) {
    data <- data[!is.na(data$percent_drop) & !is.na(data$runtime) & !is.na(data$next5_runtime_median),]
    if (nrow(data) < 4) {
        return(NA)
    }
    drop_rank <- rank(data$percent_drop)
    runtime_rank <- rank(data$runtime)
    next5_rank <- rank(data$next5_runtime_median)
    drop_resid <- residuals(lm(drop_rank ~ runtime_rank))
    next5_resid <- residuals(lm(next5_rank ~ runtime_rank))
    suppressWarnings(cor(drop_resid, next5_resid, method='pearson'))
}

threshold_levels <- c('<2%', '2-5%', '5-10%', '>10%')
cycles$drop_bucket <- cut(
    cycles$percent_drop,
    breaks=c(-Inf, 2, 5, 10, Inf),
    labels=threshold_levels,
    right=FALSE
)

bucket_summary <- data.frame(
    bucket=threshold_levels,
    n=0,
    median_runtime=NA,
    p75_runtime=NA,
    p95_runtime=NA,
    median_next5_runtime=NA,
    p75_next5_runtime=NA,
    p95_next5_runtime=NA
)

if (nrow(cycles) > 0) {
    for (i in seq_along(threshold_levels)) {
        rows <- cycles[cycles$drop_bucket == threshold_levels[i],]
        bucket_summary$n[i] <- nrow(rows)
        if (nrow(rows) > 0) {
            bucket_summary$median_runtime[i] <- median(rows$runtime, na.rm=TRUE)
            bucket_summary$p75_runtime[i] <- quantile(rows$runtime, 0.75, na.rm=TRUE, names=FALSE)
            bucket_summary$p95_runtime[i] <- quantile(rows$runtime, 0.95, na.rm=TRUE, names=FALSE)
            bucket_summary$median_next5_runtime[i] <- median(rows$next5_runtime_median, na.rm=TRUE)
            bucket_summary$p75_next5_runtime[i] <- quantile(rows$next5_runtime_median, 0.75, na.rm=TRUE, names=FALSE)
            bucket_summary$p95_next5_runtime[i] <- quantile(rows$next5_runtime_median, 0.95, na.rm=TRUE, names=FALSE)
        }
    }
}

long_recovery <- cycles[cycles$recovery_minutes >= 360,]
cor_summary <- data.frame(
    metric=c(
        'all_cycles_current_runtime',
        'six_hour_recovery_current_runtime',
        'all_cycles_next5_runtime',
        'next5_runtime_controlling_current_runtime'
    ),
    spearman_rho=c(
        spearman_value(cycles, 'percent_drop', 'runtime'),
        spearman_value(long_recovery, 'percent_drop', 'runtime'),
        spearman_value(cycles, 'percent_drop', 'next5_runtime_median'),
        partial_spearman(cycles)
    ),
    n=c(
        sum(!is.na(cycles$percent_drop) & !is.na(cycles$runtime)),
        sum(!is.na(long_recovery$percent_drop) & !is.na(long_recovery$runtime)),
        sum(!is.na(cycles$percent_drop) & !is.na(cycles$next5_runtime_median)),
        sum(!is.na(cycles$percent_drop) & !is.na(cycles$runtime) & !is.na(cycles$next5_runtime_median))
    )
)

write.csv(bucket_summary, summary_fname, row.names=FALSE)
write.csv(cor_summary, correlation_fname, row.names=FALSE)

plot_relationship <- function(data, xcol, ycol, xlab, ylab, main, note) {
    data <- data[!is.na(data[[xcol]]) & !is.na(data[[ycol]]),]
    par(
        bg=cycle_bg,
        mar=c(4.2, 4.8, 4, 1.5),
        mgp=c(2.6, 0.7, 0),
        tcl=-0.25,
        col.axis=cycle_axis,
        col.lab=cycle_axis,
        col.main=cycle_text,
        fg=cycle_axis,
        bty='n',
        las=1
    )

    if (nrow(data) > 0) {
        xlim <- range(data[[xcol]], na.rm=TRUE)
        ylim <- range(data[[ycol]], na.rm=TRUE)
        xpad <- max(0.5, diff(xlim) * 0.05)
        ypad <- max(0.2, diff(ylim) * 0.08)
        xlim <- c(xlim[1] - xpad, xlim[2] + xpad)
        ylim <- c(max(0, ylim[1] - ypad), ylim[2] + ypad)
        xseq <- pretty(xlim)
        yseq <- pretty(ylim)
        raw_colors <- month_colors[data$month_label]
        raw_colors[is.na(raw_colors)] <- cycle_grey

        cycle_draw_panel(xlim, range(yseq), xlab, ylab, main)
        cycle_grid_lines(h=yseq, v=xseq)
        axis(side=1, at=xseq, labels=xseq, col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
        cycle_axis_y(yseq)
        points(data[[xcol]], data[[ycol]], col=adjustcolor(raw_colors, alpha.f=0.55), pch=19, cex=0.6)

        if (nrow(data) >= 10 && length(unique(data[[xcol]])) >= 4) {
            trend <- lowess(data[[xcol]], data[[ycol]], f=0.4, iter=3)
            lines(trend$x, trend$y, col=cycle_text, lwd=2)
        }

        legend_months <- names(month_colors)[names(month_colors) %in% unique(data$month_label)]
        cycle_legend('topleft', legend=legend_months, col=month_colors[legend_months], pch=19, inset=0.01, cex=0.82)
        text(xlim[2], yseq[length(yseq)], labels=note, adj=c(1, 1.1), cex=0.85, col=cycle_axis)
    } else {
        cycle_draw_panel(c(0, 1), c(0, 1), xlab, ylab, main)
        text(0.5, 0.5, 'No cycles found', col=cycle_axis)
    }
}

png(filename=fname, width=1200, height=900, units='px', pointsize=12, bg=cycle_bg)
layout(matrix(c(1, 2, 3, 4), nrow=2, byrow=TRUE), widths=c(1, 1), heights=c(1, 1))

plot_relationship(
    cycles,
    'percent_drop',
    'runtime',
    'Within-cycle power drop (%)',
    'Runtime (minutes)',
    'Power Drop vs Runtime - All Cycles Since May 1',
    spearman_label(cycles, 'percent_drop', 'runtime')
)

plot_relationship(
    long_recovery,
    'percent_drop',
    'runtime',
    'Within-cycle power drop (%)',
    'Runtime after >=6 hr recovery (minutes)',
    'Power Drop vs Runtime - >=6 hr Recovery',
    spearman_label(long_recovery, 'percent_drop', 'runtime')
)

partial_note <- partial_spearman(cycles)
warning_note <- paste(
    spearman_label(cycles, 'percent_drop', 'next5_runtime_median'),
    sprintf('partial vs current runtime: %s', ifelse(is.na(partial_note), 'n/a', sprintf('%.2f', partial_note))),
    sep='; '
)
plot_relationship(
    cycles,
    'percent_drop',
    'next5_runtime_median',
    'Within-cycle power drop (%)',
    'Median runtime of next 5 cycles (minutes)',
    'Early Warning Test - Next 5 Cycles',
    warning_note
)

par(
    bg=cycle_bg,
    mar=c(3, 1, 4, 1),
    col.axis=cycle_axis,
    col.lab=cycle_axis,
    col.main=cycle_text,
    fg=cycle_axis,
    bty='n'
)
plot(c(0, 1), c(0, 1), type='n', axes=FALSE, xlab='', ylab='', main='Runtime by Power-Drop Threshold')
rect(0, 0, 1, 1, col=cycle_panel, border=NA)
headers <- c('Drop', 'n', 'Med', 'P75', 'P95', 'Next5 med', 'Next5 P75', 'Next5 P95')
xpos <- c(0.04, 0.2, 0.34, 0.47, 0.6, 0.74, 0.87, 0.98)
adj <- c(0, rep(1, length(headers) - 1))
for (i in seq_along(headers)) {
    text(xpos[i], 0.86, headers[i], adj=adj[i], font=2, col=cycle_text, cex=0.82)
}
for (i in 1:nrow(bucket_summary)) {
    y <- 0.86 - i * 0.16
    values <- c(
        as.character(bucket_summary$bucket[i]),
        format(bucket_summary$n[i], big.mark=','),
        sprintf('%.2f', bucket_summary$median_runtime[i]),
        sprintf('%.2f', bucket_summary$p75_runtime[i]),
        sprintf('%.2f', bucket_summary$p95_runtime[i]),
        sprintf('%.2f', bucket_summary$median_next5_runtime[i]),
        sprintf('%.2f', bucket_summary$p75_next5_runtime[i]),
        sprintf('%.2f', bucket_summary$p95_next5_runtime[i])
    )
    values[grepl('NA', values)] <- '-'
    for (j in seq_along(values)) {
        text(xpos[j], y, values[j], adj=adj[j], col=cycle_axis, cex=0.82)
    }
}
text(0.04, 0.08, 'Runtime values are minutes. Next5 uses the following five pump cycles.', adj=0, col=cycle_axis, cex=0.78)

dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
system(paste("scp", summary_fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
system(paste("scp", correlation_fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
