if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

query <- "WITH bounds AS (SELECT CURRENT_TIMESTAMP - INTERVAL '24 HOURS' AS start_time, CURRENT_TIMESTAMP AS end_time) SELECT GREATEST(wc.cycle_start, b.start_time) AS cycle_start, LEAST(wc.cycle_end, b.end_time) AS cycle_end, wc.runtime FROM water_statistics.water_cycles wc, bounds b WHERE wc.cycle_end >= b.start_time AND wc.cycle_start <= b.end_time ORDER BY wc.cycle_start;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_timeline_24_hours.png'
mintime <- Sys.time() - 86400
maxtime <- Sys.time()
hourseq <- seq(as.POSIXct(format(mintime, '%Y-%m-%d %H:00:00')), maxtime, by='hour')

png(filename=fname, width=1024, height=160, units='px', pointsize=12, bg='#f8fafc')
par(
    bg='#f8fafc',
    mar=c(2.5, 1, 2.2, 1),
    mgp=c(1.6, 0.5, 0),
    tcl=-0.25,
    col.axis='#475569',
    col.main='#0f172a',
    fg='#475569',
    bty='n'
)
plot(c(mintime, maxtime), c(0, 1), type='n', xlim=c(mintime, maxtime), ylim=c(0, 1), xlab="", ylab="", main="Well Pump Cycles - Last 24 Hours", xaxt='n', yaxt='n')
rect(mintime, 0, maxtime, 1, col='#ffffff', border=NA)
abline(v=hourseq, col='#e2e8f0')
segments(mintime, 0.5, maxtime, 0.5, col='#cbd5e1', lwd=18, lend=1)
if (nrow(res) > 0) {
    segments(res$cycle_start, 0.5, res$cycle_end, 0.5, col='#2563eb', lwd=18, lend=1)
}
axis(side=1, at=hourseq, labels=format(hourseq, '%H'), col=NA, col.ticks='#475569', col.axis='#475569')
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
