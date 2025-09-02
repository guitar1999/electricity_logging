if (! 'package:RPostgreSQL' %in% search()) {
  library(RPostgreSQL)
  source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}


query <- "SELECT sum_date, avg_cycle_time, rolling_avg_cycle_time_7d, rolling_avg_cycle_time_30d, rolling_avg_cycle_time_90d FROM water_statistics.water_statistics_daily_cycle_view ORDER BY sum_date DESC LIMIT 90;"
res <- dbGetQuery(con, query)

plotmin <- floor(min(res$avg_cycle_time, res$rolling_avg_cycle_time_90d))
plotmax <- ceiling(max(res$avg_cycle_time, res$rolling_avg_cycle_time_90d))
vseq <- seq(plotmin, plotmax, 1)

fname <- '/tmp/water_cycle_time.png'

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
plot(res$sum_date, res$avg_cycle_time, type='l', col='white', ylim=c(plotmin, plotmax), yaxt='n', xlab="Date", ylab="Minutes", main="Avg Well Pump Cycle Time", lwd=3)
axis(side=2, at=vseq, labels=vseq, las=1)
abline(h=vseq, col='grey', lty=3)
lines(res$sum_date, res$avg_cycle_time, col='lightblue', lwd=3)
lines(res$sum_date, res$rolling_avg_cycle_time_90d, col='orange')
legend('topleft', legend=c('Daily Average', '90d Average'), col=c('lightblue', 'orange'), lty=c(1,1), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
