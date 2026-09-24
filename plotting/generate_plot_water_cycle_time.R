if (! 'package:RPostgreSQL' %in% search()) {
  library(RPostgreSQL)
  source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}


query <- "SELECT sum_date, median_cycle_time, rolling_avg_cycle_time_median_90d, lifetime_median_cycle_time FROM water_statistics.water_statistics_daily_cycle_view WHERE sum_date <= CURRENT_DATE ORDER BY sum_date;"
history <- dbGetQuery(con, query)
history$sum_date <- as.Date(history$sum_date)
today <- Sys.Date()
res <- history[history$sum_date >= today - 89, ]

plotmin <- 0
plotmax <- ceiling(max(1, res$median_cycle_time, res$rolling_avg_cycle_time_median_90d, res$lifetime_median_cycle_time, na.rm=TRUE))
vseq <- seq(plotmin, plotmax, 1)

fname <- '/tmp/water_cycle_time_median.png'

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
plot(res$sum_date, res$median_cycle_time, type='l', col='white', xlim=c(today - 89, today), ylim=c(plotmin, plotmax), yaxt='n', xlab="Date", ylab="Minutes", main="Median Well Pump Cycle Time", lwd=3)
axis(side=2, at=vseq, labels=vseq, las=1)
abline(h=vseq, col='grey', lty=3)
abline(h=res$lifetime_median_cycle_time[1], col='darkblue')
lines(res$sum_date, res$median_cycle_time, col='lightblue', lwd=3)
lines(res$sum_date, res$rolling_avg_cycle_time_median_90d, col='orange')
legend('topleft', legend=c('Daily Median', '90d Avg Daily Median', 'Overall Median'), col=c('lightblue', 'orange', 'darkblue'), lty=c(1,1,1), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

# Shift by calendar year (not 365 days), including windows crossing New Year.
# Unmatched February 29 dates are omitted rather than moved to March 1.
current_year <- as.integer(format(today, '%Y'))
first_year <- if (nrow(history)) min(as.integer(format(history$sum_date, '%Y'))) else current_year
comparisons <- lapply(seq.int(0, current_year - first_year), function(offset) {
    shifted <- history
    shifted$plot_date <- as.Date(paste0(
        as.integer(format(history$sum_date, '%Y')) + offset,
        format(history$sum_date, '-%m-%d')), format='%Y-%m-%d')
    shifted <- shifted[!is.na(shifted$plot_date) & shifted$plot_date >= today - 89 & shifted$plot_date <= today, ]
    shifted$comparison_year <- rep(current_year - offset, nrow(shifted))
    shifted
})
comparison <- do.call(rbind, comparisons)
years <- sort(unique(comparison$comparison_year))
colors <- setNames(c(if (length(years) > 1) grey.colors(length(years) - 1, start=0.72, end=0.35), '#dc2626'), years)
ymax <- ceiling(max(1, comparison$median_cycle_time, na.rm=TRUE))
fname <- '/tmp/water_cycle_time_median_year_over_year.png'
png(filename=fname, width=1024, height=450, units='px', pointsize=12, bg='white')
par(mar=c(4, 4, 4, 1), col.axis='#475569', col.lab='#334155', fg='#334155')
plot(c(today - 89, today), c(0, ymax), type='n', xlab='Date (calendar aligned)', ylab='Minutes',
     main='Daily Median Well Pump Cycle Time - Year over Year', xaxt='n', yaxt='n', bty='n')
ticks <- pretty(c(0, ymax))
abline(h=ticks, col='#e2e8f0')
axis(2, at=ticks, las=1, tick=FALSE)
axis.Date(1, at=seq(today - 89, today, by='14 days'), format='%b %d')
for (year in years) {
    series <- comparison[comparison$comparison_year == year, ]
    # Insert missing days so lines never bridge outages or absent cycle data.
    series <- merge(data.frame(plot_date=seq(today - 89, today, by='day')), series, by='plot_date', all.x=TRUE)
    lines(series$plot_date, series$median_cycle_time,
          col=colors[as.character(year)], lwd=if (year == current_year) 2.5 else 1.5)
}
legend('topleft', legend=years, col=colors[as.character(years)], lty=1, lwd=2, bty='n', horiz=TRUE, cex=0.85)
dev.off()
system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
