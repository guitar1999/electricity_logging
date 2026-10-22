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

# Water years are named for their ending year. A leap-year reference preserves
# February 29 while aligning every other date by month/day across all years.
water_year <- function(dates) {
    as.integer(format(dates, '%Y')) + as.integer(format(dates, '%m') >= '10')
}
current_year <- water_year(today)
comparison <- history
comparison$comparison_year <- water_year(comparison$sum_date)
comparison$plot_date <- as.Date(paste0(
    ifelse(format(comparison$sum_date, '%m') >= '10', '1999', '2000'),
    format(comparison$sum_date, '-%m-%d')))
plot_start <- as.Date('1999-10-01')
plot_end <- as.Date('2000-09-30')
years <- sort(unique(comparison$comparison_year))
# Keep the emphasis on recent water years as the calendar advances.
style_index <- pmin(4L, pmax(0L, current_year - years)) + 1L
palette <- c('#dc2626', '#2563eb', '#4b5563', '#9ca3af', '#d1d5db')
alphas <- c(1.00, 0.90, 0.70, 0.40, 0.20)
widths <- c(2.2, 1.8, 1.3, 1.0, 0.8)
colors <- setNames(vapply(style_index, function(i) {
    adjustcolor(palette[i], alpha.f=alphas[i])
}, character(1)), years)
line_widths <- setNames(widths[style_index], years)
ymax <- ceiling(max(1, comparison$median_cycle_time, na.rm=TRUE))
fname <- '/tmp/water_cycle_time_median_year_over_year.png'
png(filename=fname, width=1024, height=450, units='px', pointsize=12, bg='white')
par(mar=c(4, 4, 4, 1), col.axis='#475569', col.lab='#334155', fg='#334155')
plot(c(plot_start, plot_end), c(0, ymax), type='n', xlab='Water year (Oct 1 - Sep 30; labeled by ending year)', ylab='Minutes',
     main='Daily Median Well Pump Cycle Time - Water Year Comparison', xaxt='n', yaxt='n', bty='n')
ticks <- pretty(c(0, ymax))
abline(h=ticks, col='#e2e8f0')
axis(2, at=ticks, las=1, tick=FALSE)
axis.Date(1, at=c(seq(plot_start, as.Date('2000-09-01'), by='month'), plot_end), format='%b %d')
for (year in years) {
    series <- comparison[comparison$comparison_year == year, ]
    # Insert missing days so lines never bridge outages or absent cycle data.
    calendar <- seq(plot_start, plot_end, by='day')
    if (!(year %% 4 == 0 && (year %% 100 != 0 || year %% 400 == 0))) {
        calendar <- calendar[format(calendar, '%m-%d') != '02-29']
    }
    series <- merge(data.frame(plot_date=calendar), series, by='plot_date', all.x=TRUE)
    lines(series$plot_date, series$median_cycle_time,
          col=colors[as.character(year)], lwd=line_widths[as.character(year)])
}
legend('topleft', legend=years, col=colors[as.character(years)], lty=1,
       lwd=line_widths[as.character(years)], bty='n', horiz=TRUE, cex=0.85)
dev.off()
system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
