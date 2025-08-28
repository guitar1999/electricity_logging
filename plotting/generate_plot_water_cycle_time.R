if (! 'package:RPostgreSQL' %in% search()) {
  library(RPostgreSQL)
  source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}


query <- "SELECT sum_date, avg_cycle_time FROM water_statistics.water_statistics_daily_cycle_view ORDER BY sum_date DESC LIMIT 30;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_cycle_time.png'

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
plot(res$sum_date, res$avg_cycle_time, type='l', col='lightblue', xlab="Date", ylab="Minutes", main="Avg Well Pump Cycle Time", lwd=3)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
