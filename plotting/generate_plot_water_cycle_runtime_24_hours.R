if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_plot_style.R', sep=''))

query <- "WITH bounds AS (SELECT CURRENT_TIMESTAMP - INTERVAL '24 HOURS' AS start_time, CURRENT_TIMESTAMP AS end_time) SELECT wc.cycle_start, wc.runtime FROM water_statistics.water_cycles wc, bounds b WHERE wc.cycle_start >= b.start_time AND wc.cycle_start <= b.end_time ORDER BY wc.cycle_start;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_runtime_24_hours.png'
mintime <- Sys.time() - 86400
maxtime <- Sys.time()
maxruntime <- ifelse(nrow(res) > 0, max(1, res$runtime, na.rm=TRUE), 1)
vseq <- seq(0, ceiling(maxruntime), 1)
hseq <- seq(mintime, maxtime, 1800)
hourseq <- seq(mintime, maxtime, 3600)

# Do some sunrise and sunset calculations
today <- Sys.Date()
query2 <- paste("SELECT (date || ' ' || sunrise)::timestamp AS sunrise, (date || ' ' || sunset)::timestamp AS sunset FROM astronomy_data WHERE date IN ('", today - 1, "', '", today, "') ORDER BY date;", sep="")
res2 <- dbGetQuery(con, query2)


cycle_plot_init(fname)
cycle_draw_panel(c(mintime, maxtime), c(0, maxruntime), "Time", "Minutes", "Well Pump Cycle Runtime - Last 24 Hours")
cycle_grid_lines(h=vseq, v=hourseq)
cycle_axis_time(hseq)
cycle_axis_y(vseq)
abline(v=res2$sunrise, lty=2, col=cycle_orange)
abline(v=res2$sunset, lty=2, col=cycle_orange)
if (nrow(res) > 0) {
    segments(res$cycle_start, 0, res$cycle_start, res$runtime, col=cycle_blue_light, lwd=1.5)
    points(res$cycle_start, res$runtime, col=cycle_blue, pch=19)
}
cycle_legend('topright', legend=c('Cycle Runtime'), col=c(cycle_blue), pch=c(19), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
