if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}


query <- "WITH bounds AS (SELECT CURRENT_TIMESTAMP - INTERVAL '24 HOURS' AS start_time, CURRENT_TIMESTAMP AS end_time) SELECT GREATEST(wc.cycle_start, b.start_time) AS cycle_start, LEAST(wc.cycle_end, b.end_time) AS cycle_end, wc.runtime FROM water_statistics.water_cycles wc, bounds b WHERE wc.cycle_end >= b.start_time AND wc.cycle_start <= b.end_time ORDER BY wc.cycle_start;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_timeline_24_hours.png'
mintime <- Sys.time() - 86400
maxtime <- Sys.time()
hseq <- seq(mintime, maxtime, 1800)
hourseq <- seq(mintime, maxtime, 3600)

# Do some sunrise and sunset calculations
today <- Sys.Date()
query2 <- paste("SELECT (date || ' ' || sunrise)::timestamp AS sunrise, (date || ' ' || sunset)::timestamp AS sunset FROM astronomy_data WHERE date IN ('", today - 1, "', '", today, "') ORDER BY date;", sep="")
res2 <- dbGetQuery(con, query2)


png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
plot(c(mintime, maxtime), c(0, 1), type='n', xlim=c(mintime, maxtime), ylim=c(0, 1), xlab="Time", ylab="", main="Well Pump Cycles - Last 24 Hours", xaxt='n', yaxt='n')
axis(side=1, at=hseq, labels=substr(hseq, 12, 16))
abline(v=hourseq, col='black')
abline(v=res2$sunrise, lty=2, col='orange')
abline(v=res2$sunset, lty=2, col='orange')
if (nrow(res) > 0) {
    segments(res$cycle_start, 0.5, res$cycle_end, 0.5, col='steelblue', lwd=8, lend=1)
}
legend('topright', legend=c('Pump On'), col=c('steelblue'), lty=c(1), lwd=c(8), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
