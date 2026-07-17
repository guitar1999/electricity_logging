if (! 'package:RPostgreSQL' %in% search()) {
  library(RPostgreSQL)
  source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}


query <- "SELECT sum_date, avg_cycle_time, median_cycle_time, rolling_avg_cycle_time_90d, rolling_avg_cycle_time_median_90d, lifetime_median_cycle_time FROM (SELECT sum_date, avg_cycle_time, median_cycle_time, rolling_avg_cycle_time_90d, rolling_avg_cycle_time_median_90d, lifetime_median_cycle_time FROM water_statistics.water_statistics_daily_cycle_view ORDER BY sum_date DESC LIMIT 90) x ORDER BY sum_date;"
res <- dbGetQuery(con, query)

query2 <- "SELECT SUM(total_runtime) / SUM(total_cycles) as overall_avg_cycle_time FROM water_statistics.water_statistics_daily_cycle_view;"
res2 <- dbGetQuery(con, query2)

fname <- '/tmp/water_cycle_time.png'

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
plotmin <- floor(min(res$avg_cycle_time, res$rolling_avg_cycle_time_90d, res2$overall_avg_cycle_time, na.rm=TRUE))
plotmax <- ceiling(max(res$avg_cycle_time, res$rolling_avg_cycle_time_90d, res2$overall_avg_cycle_time, na.rm=TRUE))
vseq <- seq(plotmin, plotmax, 1)
plot(res$sum_date, res$avg_cycle_time, type='l', col='white', ylim=c(plotmin, plotmax), yaxt='n', xlab="Date", ylab="Minutes", main="Avg Well Pump Cycle Time", lwd=3)
axis(side=2, at=vseq, labels=vseq, las=1)
abline(h=vseq, col='grey', lty=3)
abline(h=res2$overall_avg_cycle_time, col='darkblue')
lines(res$sum_date, res$avg_cycle_time, col='lightblue', lwd=3)
lines(res$sum_date, res$rolling_avg_cycle_time_90d, col='orange')
legend('topleft', legend=c('Daily Average', '90d Average', 'Overall Average'), col=c('lightblue', 'orange', 'darkblue'), lty=c(1,1,1), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

fname <- '/tmp/water_cycle_time_median.png'

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
plotmin <- floor(min(res$median_cycle_time, res$rolling_avg_cycle_time_median_90d, res$lifetime_median_cycle_time, na.rm=TRUE))
plotmax <- ceiling(max(res$median_cycle_time, res$rolling_avg_cycle_time_median_90d, res$lifetime_median_cycle_time, na.rm=TRUE))
vseq <- seq(plotmin, plotmax, 1)
plot(res$sum_date, res$median_cycle_time, type='l', col='white', ylim=c(plotmin, plotmax), yaxt='n', xlab="Date", ylab="Minutes", main="Median Well Pump Cycle Time", lwd=3)
axis(side=2, at=vseq, labels=vseq, las=1)
abline(h=vseq, col='grey', lty=3)
abline(h=res$lifetime_median_cycle_time[1], col='darkblue')
lines(res$sum_date, res$median_cycle_time, col='lightblue', lwd=3)
lines(res$sum_date, res$rolling_avg_cycle_time_median_90d, col='orange')
legend('topleft', legend=c('Daily Median', '90d Median', 'Overall Median'), col=c('lightblue', 'orange', 'darkblue'), lty=c(1,1,1), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
