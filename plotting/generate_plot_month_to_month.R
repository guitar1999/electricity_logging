if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
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

query <- paste("SELECT DATE_PART('year', sum_date) AS year, DATE_PART('month', sum_date) AS month, DATE_PART('day', sum_date) AS day, hour, (sum_date || ' ' || hour || ':59:59')::timestamp with time zone AS timestamp, ((sum_date + ((DATE_PART('year', CURRENT_TIMESTAMP) - DATE_PART('year', sum_date))::integer || ' year')::interval)::date || ' ' || hour || ':59:59')::timestamp with time zone AS plotstamp, kwh, SUM(kwh) OVER (PARTITION BY date_part('year', sum_date) ORDER BY date_part('day', sum_date), hour) AS cumulative_kwh FROM electricity_statistics.electricity_sums_hourly_best_available WHERE DATE_PART('month', sum_date) = ", month, " ORDER BY DATE_PART('year', sum_date), DATE_PART('day', sum_date), hour;", sep="")
measurements <- dbGetQuery(con, query)

#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP) AS xmin;"
#xmin <- dbGetQuery(con, query)$xmin
#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP + interval '1 month') - interval '1 second' AS xmax;"
#xmax <- dbGetQuery(con, query)$xmax
xmin <- min(measurements$plotstamp)
xmax <- max(measurements$plotstamp)
pxmin <- max(measurements$timestamp)


query <- paste("SELECT kwh_avg FROM cmp_electricity_statistics_monthly WHERE month = ", month, ";", sep="")
kwhavg <- dbGetQuery(con, query)
query <- paste("SELECT timestamp, monthly_cum_avg_kwh FROM electricity_plotting.electricity_cumulative_averages WHERE DATE_PART('MONTH', timestamp) = ", month, " ORDER BY timestamp;", sep="")
cumkwhavg <- dbGetQuery(con, query)

# query <- "SELECT time, CASE WHEN minuteh IS NULL THEN minute ELSE minuteh END AS minute FROM prediction_test WHERE date_part('year', time) = date_part('year', CURRENT_TIMESTAMP) AND date_part('month', time) = date_part('month', CURRENT_TIMESTAMP) AND minute > 0 ORDER BY time;"
query <- "SELECT timestamp, cumulative_kwh FROM electricity_plotting.cumulative_predicted_use_this_month_view;"
prediction <- dbGetQuery(con, query)
# prediction <- rbind(prediction, setNames(data.frame(xmax, prediction$minute[length(prediction$minute)]), names(prediction)))
# predline <- rbind(measurements[dim(measurements)[1],c("timestamp", "cumulative_kwh")], setNames(data.frame(prediction[dim(prediction)[1],]), c(names(measurements)[5], names(measurements)[8])))

hseq <- seq(min(measurements$plotstamp), max(measurements$plotstamp) + 86400, 86400) - 3599

fname <- '/tmp/month_to_month.png'
fname2 <- paste('month_to_month_', month, '.png', sep='')
ymax <- max(c(measurements$cumulative_kwh, prediction$cumulative_kwh))

png(filename=fname, width=1200, height=500, units='px', pointsize=12, bg='white')
# Set up empty plot
plot(measurements$plotstamp, measurements$cumulative_kwh, type='l', col='white', ylim=c(0,ymax), xlab='', ylab='Cumulative kwh')
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
    lines(plotdata$plotstamp, plotdata$cumulative_kwh, col=linecolor, lwd=1.5)
}
lines(prediction$timestamp, prediction$cumulative_kwh, col='blue4', lty=5)
# lines(predline, col='darkred', lty=2, lwd=1.5)
# abline(h=kwhavg, col='orange')
lines(cumkwhavg$timestamp, cumkwhavg$monthly_cum_avg_kwh, col='orange')
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
leg.txt <- c(ghosttext, years[length(years)], "predicted total kwh", "average kwh")
leg.lty <- c(ghostlty, 1, 5, 1)
leg.col <- c(ghostcolor, 'red', 'blue4', 'orange')
legend("bottomright", legend=leg.txt, col=leg.col, lty=leg.lty, inset=0.01)
dev.off()

if (month == strftime(Sys.time(), format='%m')) {
  system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
}
system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', fname2, sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

