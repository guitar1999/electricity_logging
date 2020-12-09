if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

# Parse args in case we want to run another month
args = commandArgs(trailingOnly=TRUE)
if (length(args) == 0) {
  # We want to run the current month
  month <- strftime(Sys.time(), format='%m')
} else {
  # We want to run a specific month
  month <- args[1]
}

query <- paste("SELECT DATE_PART('year', sum_date) AS year, DATE_PART('month', sum_date) AS month, DATE_PART('day', sum_date) AS day, hour, (sum_date || ' ' || hour || ':59:59')::timestamp AS timestamp, ((sum_date + ((DATE_PART('year', CURRENT_TIMESTAMP) - DATE_PART('year', sum_date))::integer || ' year')::interval)::date || ' ' || hour || ':59:59')::timestamp AS plotstamp, gallons, SUM(gallons) OVER (PARTITION BY date_part('year', sum_date) ORDER BY date_part('day', sum_date), hour) AS cumulative_gallons FROM water_statistics.water_sums_hourly WHERE DATE_PART('month', sum_date) = ", month, " ORDER BY DATE_PART('year', sum_date), DATE_PART('day', sum_date), hour;", sep="")
measurements <- dbGetQuery(con, query)
measurements$cumulative_gallons <- measurements$cumulative_gallons

#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP) AS xmin;"
#xmin <- dbGetQuery(con, query)$xmin
#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP + interval '1 month') - interval '1 second' AS xmax;"
#xmax <- dbGetQuery(con, query)$xmax
xmin <- min(measurements$plotstamp)
xmax <- max(measurements$plotstamp)
pxmin <- max(measurements$timestamp)
pymin <- max(measurements$cumulative_gallons[measurements$timestamp == pxmin])

query <- paste("SELECT gallons_avg FROM water_statistics.water_statistics_monthly_view WHERE month = ", month, ";", sep="")
gallonsavg <- dbGetQuery(con, query) / 60
query <- paste("SELECT timestamp, monthly_cum_avg_gallons FROM water_plotting.water_cumulative_averages WHERE DATE_PART('MONTH', timestamp) = ", month, " ORDER BY timestamp;", sep="")
cumgallonsavg <- dbGetQuery(con, query)
# query <- "SELECT time, CASE WHEN minuteh IS NULL THEN minute ELSE minuteh END AS minute FROM prediction_test WHERE date_part('year', time) = date_part('year', CURRENT_TIMESTAMP) AND date_part('month', time) = date_part('month', CURRENT_TIMESTAMP) AND minute > 0 ORDER BY time;"
query <- "SELECT timestamp, gallons FROM water_plotting.cumulative_predicted_use_this_month_view ORDER BY timestamp;"
prediction <- dbGetQuery(con, query)
prediction$gallons <- prediction$gallons / 60
prediction <- rbind(measurements[dim(measurements)[1],c("timestamp", "cumulative_gallons")], setNames(data.frame(prediction), c(names(measurements)[5], names(measurements)[8])))

hseq <- seq(min(measurements$plotstamp), max(measurements$plotstamp) + 86400, 86400) - 3599

fname <- '/var/www/electricity/water_month_to_month.png'
fname2 <- paste('water_month_to_month_', month, '.png', sep='')
ymax <- max(c(measurements$cumulative_gallons, prediction$cumulative_gallons))

png(filename=fname, width=1200, height=500, units='px', pointsize=12, bg='white')
# Set up empty plot
plot(measurements$plotstamp, measurements$cumulative_gallons, type='l', col='white', ylim=c(0,ymax), xlab='', ylab='Cumulative Gallons')
abline(v=hseq, col='lightgrey', lty=3)
years <- seq(min(measurements$year), max(measurements$year))
ghostyears <- length(years) - 1
ghostlty <- rep(1, ghostyears)
ghostcolors <- grey.colors(ghostyears,start=0.8, end=0.5)
for (i in seq(1, length(years))){
    plotdata <- subset(measurements, measurements$year == years[i])
    if (years[i] < max(years)) {
        linecolor <- ghostcolors[i]
    } else {
        linecolor <- 'red'
    }
    lines(plotdata$plotstamp, plotdata$cumulative_gallons, col=linecolor, lwd=1.5)
}
lines(prediction$timestamp, prediction$cumulative_gallons, col='blue4', lty=5)
# lines(predline, col='darkred', lty=2, lwd=1.5)
#abline(h=gallonsavg, col='orange')
lines(cumgallonsavg$timestamp, cumgallonsavg$monthly_cum_avg_gallons / 60, col='orange')
if (ghostyears == 0) {
  ghosttext <- ''
  ghostcolor <- 'white'
} else if (ghostyears == 1) {
  ghosttext <- years[1]
  ghostcolor <- c(ghostcolors[1])
} else if (ghostyears == 2) {
  ghosttext <- c(years[1], years[2])
  ghostcolor <- c(ghostcolors[1], ghostcolors[ghostyears])
} else {
  ghosttext <- c(years[1], '. . . ', years[ghostyears])
  ghostcolor <- c(ghostcolors[1], 'white', ghostcolors[ghostyears])
}
leg.txt <- c(ghosttext, years[length(years)], "predicted total gallons", "average gallons")
leg.lty <- c(ghostlty, 1, 5, 1)
leg.col <- c(ghostcolor, 'red', 'blue4', 'orange')
legend("bottomright", legend=leg.txt, col=leg.col, lty=leg.lty, inset=0.01)
dev.off()

if (month == strftime(Sys.time(), format='%m')) {
  system(paste("scp", fname, paste(webhost, ":/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=""), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
}
system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

