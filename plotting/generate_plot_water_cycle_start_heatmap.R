if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}


query <- "SELECT DATE_PART('DOW', cycle_start)::INTEGER AS dow, DATE_PART('HOUR', cycle_start)::INTEGER AS hour, COUNT(*) AS cycles FROM water_statistics.water_cycles WHERE cycle_start >= CURRENT_TIMESTAMP - INTERVAL '90 DAYS' GROUP BY 1, 2 ORDER BY 1, 2;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_start_heatmap.png'
counts <- matrix(0, nrow=24, ncol=7)
if (nrow(res) > 0) {
    for (i in 1:nrow(res)) {
        counts[res$hour[i] + 1, res$dow[i] + 1] <- res$cycles[i]
    }
}
colors <- colorRampPalette(c('white', 'lightblue', 'steelblue', 'navy'))(20)

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
image(0:23, 0:6, counts, col=colors, xlab="Hour of Day", ylab="Day of Week", main="Well Pump Cycle Starts by Hour and Day - Last 90 Days", xaxt='n', yaxt='n')
axis(side=1, at=seq(0,23,2), labels=seq(0,23,2))
axis(side=2, at=0:6, labels=c('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'), las=1)
text(expand.grid(0:23, 0:6), labels=as.vector(counts), cex=0.7)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
