if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}


query <- "SELECT cycle_start::DATE AS cycle_date, DATE_PART('HOUR', cycle_start) + DATE_PART('MINUTE', cycle_start) / 60 + DATE_PART('SECOND', cycle_start) / 3600 AS hour_of_day, runtime FROM water_statistics.water_cycles WHERE cycle_start >= CURRENT_DATE - INTERVAL '29 DAYS' ORDER BY cycle_start;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_fingerprint_30_days.png'
dates <- seq(Sys.Date() - 29, Sys.Date(), 1)
res$day_index <- match(res$cycle_date, dates)
maxruntime <- ifelse(nrow(res) > 0, max(1, res$runtime, na.rm=TRUE), 1)
pointsize <- ifelse(nrow(res) > 0, 0.8 + 2.2 * pmin(res$runtime / maxruntime, 1), 1)

png(filename=fname, width=1024, height=700, units='px', pointsize=12, bg='white')
plot(c(0, 24), c(1, length(dates)), type='n', xlim=c(0,24), ylim=c(1,length(dates)), xlab="Hour of Day", ylab="Date", main="Well Pump Cycle Fingerprint - Last 30 Days", xaxt='n', yaxt='n')
axis(side=1, at=seq(0,24,2), labels=seq(0,24,2))
axis(side=2, at=seq(1, length(dates), 2), labels=format(dates[seq(1, length(dates), 2)], '%m-%d'), las=1)
abline(v=seq(0,24,2), col='grey', lty=3)
abline(h=seq(1, length(dates), 1), col='grey', lty=3)
if (nrow(res) > 0) {
    points(res$hour_of_day, res$day_index, col='steelblue', pch=19, cex=pointsize)
}
legend('topright', legend=c('Cycle Start'), col=c('steelblue'), pch=c(19), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
