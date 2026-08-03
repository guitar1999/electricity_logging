if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_plot_style.R', sep=''))

query <- "SELECT runtime, CASE WHEN cycle_start >= CURRENT_TIMESTAMP - INTERVAL '7 DAYS' THEN '7d' WHEN cycle_start >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS' THEN '30d' ELSE '90d' END AS window FROM water_statistics.water_cycles_view WHERE cycle_start >= CURRENT_TIMESTAMP - INTERVAL '90 DAYS' ORDER BY runtime;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_runtime_distribution.png'
maxruntime <- ifelse(nrow(res) > 0, max(1, res$runtime, na.rm=TRUE), 1)
breaks <- seq(0, ceiling(maxruntime * 2) / 2, 0.25)
if (length(breaks) < 2) {
    breaks <- c(0, 1)
}

hist90 <- hist(res$runtime, breaks=breaks, plot=FALSE)
runtime30 <- res$runtime[res$window %in% c('7d', '30d')]
runtime7 <- res$runtime[res$window == '7d']
hist30 <- hist90
hist7 <- hist90
hist30$counts <- rep(0, length(hist30$counts))
hist7$counts <- rep(0, length(hist7$counts))
if (length(runtime30) > 0) {
    hist30 <- hist(runtime30, breaks=breaks, plot=FALSE)
}
if (length(runtime7) > 0) {
    hist7 <- hist(runtime7, breaks=breaks, plot=FALSE)
}
plotmax <- max(1, hist90$counts, hist30$counts, hist7$counts)

cycle_plot_init(fname)
cycle_draw_panel(c(min(breaks), max(breaks)), c(0,plotmax), "Minutes", "Cycles", "Well Pump Cycle Runtime Distribution")
vseq <- pretty(c(0, plotmax))
cycle_grid_lines(h=vseq)
axis(side=1, col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
cycle_axis_y(vseq)
lines(hist90$mids, hist90$counts, type='s', col=cycle_grey, lwd=2)
lines(hist30$mids, hist30$counts, type='s', col=cycle_blue, lwd=2)
lines(hist7$mids, hist7$counts, type='s', col=cycle_orange, lwd=2)
cycle_legend('topright', legend=c('90d', '30d', '7d'), col=c(cycle_grey, cycle_blue, cycle_orange), lty=c(1,1,1), lwd=c(2,2,2), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
