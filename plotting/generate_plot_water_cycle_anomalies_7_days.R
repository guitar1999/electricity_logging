if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_plot_style.R', sep=''))

query <- "WITH thresholds AS (SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY runtime) AS runtime_p95, PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY runtime) AS runtime_p05 FROM water_statistics.water_cycles WHERE cycle_start >= CURRENT_TIMESTAMP - INTERVAL '90 DAYS') SELECT wc.cycle_start, wc.runtime, t.runtime_p05, t.runtime_p95 FROM water_statistics.water_cycles wc, thresholds t WHERE wc.cycle_start >= CURRENT_TIMESTAMP - INTERVAL '7 DAYS' ORDER BY wc.cycle_start;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_anomalies_7_days.png'
mintime <- Sys.time() - 86400 * 7
maxtime <- Sys.time()
maxruntime <- ifelse(nrow(res) > 0, max(1, res$runtime, res$runtime_p95, na.rm=TRUE), 1)
vseq <- seq(0, ceiling(maxruntime), 1)
hseq <- seq(mintime, maxtime, 86400)
pointcol <- ifelse(nrow(res) > 0 & res$runtime >= res$runtime_p95, cycle_red, ifelse(nrow(res) > 0 & res$runtime <= res$runtime_p05, cycle_gold, cycle_blue))

cycle_plot_init(fname)
cycle_draw_panel(c(mintime, maxtime), c(0, maxruntime), "Date", "Minutes", "Well Pump Runtime Anomalies - Last 7 Days")
cycle_grid_lines(h=vseq, v=hseq)
cycle_axis_time(hseq, format(hseq, '%m-%d'))
cycle_axis_y(vseq)
if (nrow(res) > 0) {
    abline(h=res$runtime_p95[1], col=cycle_red, lty=2)
    abline(h=res$runtime_p05[1], col=cycle_gold, lty=2)
    points(res$cycle_start, res$runtime, col=pointcol, pch=19)
}
cycle_legend('topright', legend=c('Normal', '>= 90d p95', '<= 90d p05'), col=c(cycle_blue, cycle_red, cycle_gold), pch=c(19,19,19), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
