if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_plot_style.R', sep=''))

query <- "WITH thresholds AS (SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY runtime) AS runtime_p95, PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY runtime) AS runtime_p05 FROM water_statistics.water_cycles_view) SELECT wc.cycle_start, wc.runtime, t.runtime_p05, t.runtime_p95 FROM water_statistics.water_cycles_view wc, thresholds t WHERE wc.cycle_start >= CURRENT_TIMESTAMP - INTERVAL '7 DAYS' ORDER BY wc.cycle_start;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_anomalies_7_days.png'
mintime <- Sys.time() - 86400 * 7
maxtime <- Sys.time()
runtime_cap <- 10
vseq <- seq(0, runtime_cap, 1)
hseq <- seq(mintime, maxtime, 86400)
pointcol <- ifelse(nrow(res) > 0 & res$runtime >= res$runtime_p95, cycle_red, ifelse(nrow(res) > 0 & res$runtime <= res$runtime_p05, cycle_gold, cycle_blue))

best_legend_position <- function(plot_data, xlim, ylim, line_y=NULL) {
    positions <- c('topright', 'topleft', 'bottomright', 'bottomleft')
    x_span <- as.numeric(difftime(xlim[2], xlim[1], units='secs'))
    y_span <- ylim[2] - ylim[1]
    legend_x_span <- x_span * 0.28
    legend_y_span <- y_span * 0.22
    inset_x <- x_span * 0.02
    inset_y <- y_span * 0.03

    score_position <- function(position) {
        if (grepl('right', position)) {
            xmin <- xlim[2] - inset_x - legend_x_span
            xmax <- xlim[2] - inset_x
        } else {
            xmin <- xlim[1] + inset_x
            xmax <- xlim[1] + inset_x + legend_x_span
        }
        if (grepl('top', position)) {
            ymin <- ylim[2] - inset_y - legend_y_span
            ymax <- ylim[2] - inset_y
        } else {
            ymin <- ylim[1] + inset_y
            ymax <- ylim[1] + inset_y + legend_y_span
        }

        point_score <- 0
        if (nrow(plot_data) > 0) {
            point_score <- sum(
                plot_data$cycle_start >= xmin &
                plot_data$cycle_start <= xmax &
                plot_data$plot_runtime >= ymin &
                plot_data$plot_runtime <= ymax
            )
        }

        line_score <- 0
        if (!is.null(line_y)) {
            line_score <- sum(line_y >= ymin & line_y <= ymax, na.rm=TRUE) * 2
        }
        point_score + line_score
    }

    positions[which.min(sapply(positions, score_position))]
}

cycle_plot_init(fname)
cycle_draw_panel(c(mintime, maxtime), c(0, runtime_cap), "Date", "Minutes", "Well Pump Runtime Anomalies - Last 7 Days")
cycle_grid_lines(h=vseq, v=hseq)
cycle_axis_time(hseq, format(hseq, '%m-%d'))
cycle_axis_y(vseq)
if (nrow(res) > 0) {
    if (res$runtime_p95[1] <= runtime_cap) {
        abline(h=res$runtime_p95[1], col=cycle_red, lty=2)
    }
    if (res$runtime_p05[1] <= runtime_cap) {
        abline(h=res$runtime_p05[1], col=cycle_gold, lty=2)
    }
    plot_runtime <- pmin(res$runtime, runtime_cap)
    point_pch <- ifelse(res$runtime > runtime_cap, 8, 19)
    points(res$cycle_start, plot_runtime, col=pointcol, pch=point_pch)
}
legend_data <- data.frame()
legend_lines <- NULL
if (nrow(res) > 0) {
    legend_data <- data.frame(cycle_start=res$cycle_start, plot_runtime=pmin(res$runtime, runtime_cap))
    legend_lines <- c(res$runtime_p95[1], res$runtime_p05[1])
    legend_lines <- legend_lines[legend_lines <= runtime_cap]
}
legend_position <- best_legend_position(legend_data, c(mintime, maxtime), c(0, runtime_cap), legend_lines)
cycle_legend(legend_position, legend=c('Normal', '>= lifetime p95', '<= lifetime p05', '>10 min'), col=c(cycle_blue, cycle_red, cycle_gold, cycle_red), pch=c(19,19,19,8), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
