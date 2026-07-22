if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}


query <- "WITH bounds AS (SELECT CURRENT_TIMESTAMP - INTERVAL '24 HOURS' AS start_time, CURRENT_TIMESTAMP AS end_time), cycles AS (SELECT wc.cycle_start, LAG(wc.cycle_start) OVER (ORDER BY wc.cycle_start) AS previous_cycle_start FROM water_statistics.water_cycles wc, bounds b WHERE wc.cycle_start >= b.start_time - INTERVAL '24 HOURS' AND wc.cycle_start <= b.end_time) SELECT cycle_start, EXTRACT('EPOCH' FROM cycle_start - previous_cycle_start)::NUMERIC / 60 AS minutes_since_previous FROM cycles, bounds WHERE cycle_start >= bounds.start_time AND previous_cycle_start IS NOT NULL ORDER BY cycle_start;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_cadence_24_hours.png'
mintime <- Sys.time() - 86400
maxtime <- Sys.time()
maxgap <- ifelse(nrow(res) > 0, max(10, res$minutes_since_previous, na.rm=TRUE), 10)
vstep <- ifelse(maxgap > 120, 60, ifelse(maxgap > 60, 30, 10))
vseq <- seq(0, ceiling(maxgap / vstep) * vstep, vstep)
hseq <- seq(mintime, maxtime, 1800)
hourseq <- seq(mintime, maxtime, 3600)

# Do some sunrise and sunset calculations
today <- Sys.Date()
query2 <- paste("SELECT (date || ' ' || sunrise)::timestamp AS sunrise, (date || ' ' || sunset)::timestamp AS sunset FROM astronomy_data WHERE date IN ('", today - 1, "', '", today, "') ORDER BY date;", sep="")
res2 <- dbGetQuery(con, query2)


png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
plot(c(mintime, maxtime), c(0, max(vseq)), type='n', xlim=c(mintime, maxtime), ylim=c(0,max(vseq)), xlab="Time", ylab="Minutes", main="Well Pump Cycle Cadence - Last 24 Hours", xaxt='n', yaxt='n')
axis(side=1, at=hseq, labels=substr(hseq, 12, 16))
axis(side=2, at=vseq, labels=vseq, las=1)
abline(v=hourseq, col='black')
abline(h=vseq, col='grey', lty=2)
abline(v=res2$sunrise, lty=2, col='orange')
abline(v=res2$sunset, lty=2, col='orange')
if (nrow(res) > 0) {
    segments(res$cycle_start, 0, res$cycle_start, res$minutes_since_previous, col='lightblue', lwd=1.5)
    points(res$cycle_start, res$minutes_since_previous, col='steelblue', pch=19)
}
legend('topright', legend=c('Minutes Since Previous Cycle'), col=c('steelblue'), pch=c(19), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
