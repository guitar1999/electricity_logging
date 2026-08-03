if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_plot_style.R', sep=''))

query <- "SELECT cycle_start::DATE AS cycle_date, DATE_PART('HOUR', cycle_start) + DATE_PART('MINUTE', cycle_start) / 60 + DATE_PART('SECOND', cycle_start) / 3600 AS hour_of_day, runtime FROM water_statistics.water_cycles_view WHERE cycle_start >= CURRENT_DATE - INTERVAL '29 DAYS' ORDER BY cycle_start;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_fingerprint_30_days.png'
dates <- seq(Sys.Date() - 29, Sys.Date(), 1)
res$day_index <- match(res$cycle_date, dates)
maxruntime <- ifelse(nrow(res) > 0, max(1, res$runtime, na.rm=TRUE), 1)
pointsize <- ifelse(nrow(res) > 0, 0.8 + 2.2 * pmin(res$runtime / maxruntime, 1), 1)

cycle_plot_init(fname)
cycle_draw_panel(c(0, 24), c(1, length(dates)), "Hour of Day", "Date", "Well Pump Cycle Fingerprint - Last 30 Days")
cycle_grid_lines(h=seq(1, length(dates), 1), v=seq(0,24,2))
axis(side=1, at=seq(0,24,2), labels=seq(0,24,2), col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
cycle_axis_y(seq(1, length(dates), 3), format(dates[seq(1, length(dates), 3)], '%m-%d'))
if (nrow(res) > 0) {
    points(res$hour_of_day, res$day_index, col=adjustcolor(cycle_blue, alpha.f=0.75), pch=19, cex=pointsize)
}
cycle_legend('topright', legend=c('Cycle Start'), col=c(cycle_blue), pch=c(19), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
