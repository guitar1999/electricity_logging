if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/water_cycle_plot_style.R', sep=''))

query <- "SELECT runtime, CASE WHEN cycle_start >= CURRENT_TIMESTAMP - INTERVAL '7 DAYS' THEN '7d' WHEN cycle_start >= CURRENT_TIMESTAMP - INTERVAL '30 DAYS' THEN '30d' WHEN cycle_start >= CURRENT_TIMESTAMP - INTERVAL '90 DAYS' THEN '90d' ELSE 'lifetime' END AS window FROM water_statistics.water_cycles_view WHERE runtime <= 5 ORDER BY runtime;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_runtime_distribution.png'
breaks <- seq(0, 5, 0.25)

runtime90 <- res$runtime[res$window %in% c('7d', '30d', '90d')]
runtime30 <- res$runtime[res$window %in% c('7d', '30d')]
runtime7 <- res$runtime[res$window == '7d']
hist_lifetime <- hist(res$runtime, breaks=breaks, plot=FALSE)
hist90 <- hist_lifetime
hist30 <- hist_lifetime
hist7 <- hist_lifetime
hist90$counts <- rep(0, length(hist90$counts))
hist30$counts <- rep(0, length(hist30$counts))
hist7$counts <- rep(0, length(hist7$counts))
if (length(runtime90) > 0) {
    hist90 <- hist(runtime90, breaks=breaks, plot=FALSE)
}
if (length(runtime30) > 0) {
    hist30 <- hist(runtime30, breaks=breaks, plot=FALSE)
}
if (length(runtime7) > 0) {
    hist7 <- hist(runtime7, breaks=breaks, plot=FALSE)
}
plotmax <- max(1, hist_lifetime$counts, hist90$counts, hist30$counts, hist7$counts)
to_plot_count <- function(counts) {
    log10(counts + 1)
}
format_count <- function(counts) {
    ifelse(counts >= 1000, paste(counts / 1000, 'k', sep=''), counts)
}

cycle_plot_init(fname)
cycle_draw_panel(c(min(breaks), max(breaks)), c(0, to_plot_count(plotmax)), "Minutes (<= 5)", "Cycles (log scale)", "Well Pump Cycle Runtime Distribution")
vseq_counts <- c(0, 1, 10, 100, 1000, 10000, 100000)
vseq_counts <- vseq_counts[vseq_counts <= plotmax]
vseq <- to_plot_count(vseq_counts)
minor_counts <- c(2:9, 20, 30, 40, 50, 60, 70, 80, 90, 200, 300, 400, 500, 600, 700, 800, 900, 2000, 3000, 4000, 5000, 6000, 7000, 8000, 9000, 20000, 30000, 40000, 50000, 60000, 70000, 80000, 90000)
minor_counts <- minor_counts[minor_counts <= plotmax]
abline(h=to_plot_count(minor_counts), col=adjustcolor(cycle_grid, alpha.f=0.45), lty=1)
cycle_grid_lines(h=vseq)
axis(side=1, at=seq(0, 5, 0.5), labels=seq(0, 5, 0.5), col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
cycle_axis_y(vseq, format_count(vseq_counts))
lines(hist_lifetime$mids, to_plot_count(hist_lifetime$counts), type='s', col=cycle_grey, lwd=2)
lines(hist90$mids, to_plot_count(hist90$counts), type='s', col=cycle_blue, lwd=2)
lines(hist30$mids, to_plot_count(hist30$counts), type='s', col=cycle_orange, lwd=2)
lines(hist7$mids, to_plot_count(hist7$counts), type='s', col=cycle_red, lwd=2)
cycle_legend('topright', legend=c('Lifetime', '90d', '30d', '7d'), col=c(cycle_grey, cycle_blue, cycle_orange, cycle_red), lty=c(1,1,1,1), lwd=c(2,2,2,2), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
