if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}


query <- "WITH thresholds AS (SELECT PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY runtime) AS runtime_p95, PERCENTILE_CONT(0.05) WITHIN GROUP (ORDER BY runtime) AS runtime_p05 FROM water_statistics.water_cycles WHERE cycle_start >= CURRENT_TIMESTAMP - INTERVAL '90 DAYS') SELECT wc.cycle_start, wc.runtime, t.runtime_p05, t.runtime_p95 FROM water_statistics.water_cycles wc, thresholds t WHERE wc.cycle_start >= CURRENT_TIMESTAMP - INTERVAL '7 DAYS' ORDER BY wc.cycle_start;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_anomalies_7_days.png'
mintime <- Sys.time() - 86400 * 7
maxtime <- Sys.time()
maxruntime <- ifelse(nrow(res) > 0, max(1, res$runtime, res$runtime_p95, na.rm=TRUE), 1)
vseq <- seq(0, ceiling(maxruntime), 1)
hseq <- seq(mintime, maxtime, 86400)
pointcol <- ifelse(nrow(res) > 0 & res$runtime >= res$runtime_p95, 'red', ifelse(nrow(res) > 0 & res$runtime <= res$runtime_p05, 'darkgoldenrod', 'steelblue'))

png(filename=fname, width=2048, height=700, units='px', pointsize=12, bg='white')
plot(c(mintime, maxtime), c(0, maxruntime), type='n', xlim=c(mintime, maxtime), ylim=c(0,maxruntime), xlab="Date", ylab="Minutes", main="Well Pump Runtime Anomalies - Last 7 Days", xaxt='n', yaxt='n')
axis(side=1, at=hseq, labels=format(hseq, '%m-%d %H:%M'))
axis(side=2, at=vseq, labels=vseq, las=1)
abline(v=hseq, col='black')
abline(h=vseq, col='grey', lty=2)
if (nrow(res) > 0) {
    abline(h=res$runtime_p95[1], col='red', lty=2)
    abline(h=res$runtime_p05[1], col='darkgoldenrod', lty=2)
    points(res$cycle_start, res$runtime, col=pointcol, pch=19)
}
legend('topright', legend=c('Normal', '>= 90d p95', '<= 90d p05'), col=c('steelblue', 'red', 'darkgoldenrod'), pch=c(19,19,19), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
