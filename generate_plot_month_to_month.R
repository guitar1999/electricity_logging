if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

query <- "SELECT DATE_PART('year', date) AS year, DATE_PART('month', date) AS month, DATE_PART('day', date) AS day, hour, (date || ' ' || hour || ':59:59')::timestamp AS timestamp, ((date + ((DATE_PART('year', CURRENT_TIMESTAMP) - DATE_PART('year', date))::integer || ' year')::interval)::date || ' ' || hour || ':59:59')::timestamp AS plotstamp, kwh, SUM(kwh) OVER (PARTITION BY date_part('year', date) ORDER BY date_part('day', date), hour) AS cumulative_kwh FROM electricity_sums_hourly WHERE DATE_PART('month', date) = DATE_PART('month', CURRENT_TIMESTAMP) ORDER BY DATE_PART('year', date), DATE_PART('day', date), hour;
"
measurements <- dbGetQuery(con, query)

#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP) AS xmin;"
#xmin <- dbGetQuery(con, query)$xmin
#query <- "SELECT DATE_TRUNC('month', CURRENT_TIMESTAMP + interval '1 month') - interval '1 second' AS xmax;"
#xmax <- dbGetQuery(con, query)$xmax
xmin <- min(measurements$plotstamp)
xmax <- max(measurements$plotstamp)
pxmin <- max(measurements$timestamp)


query <- "SELECT kwh_avg FROM electricity_statistics_monthly WHERE month = date_part('month', CURRENT_TIMESTAMP);"
kwhavg <- dbGetQuery(con, query)

query <- "SELECT time, CASE WHEN minuteh IS NULL THEN minute ELSE minuteh END AS minute FROM prediction_test WHERE date_part('year', time) = date_part('year', CURRENT_TIMESTAMP) AND date_part('month', time) = date_part('month', CURRENT_TIMESTAMP) AND minute > 0 ORDER BY time;"
prediction <- dbGetQuery(con, query)
prediction <- rbind(prediction, setNames(data.frame(xmax, prediction$minute[length(prediction$minute)]), names(prediction)))
predline <- rbind(measurements[dim(measurements)[1],c("timestamp", "cumulative_kwh")], setNames(data.frame(prediction[dim(prediction)[1],]), c(names(measurements)[5], names(measurements)[8])))

fname <- '/var/www/electricity/month_to_month.png'
ymax <- max(c(measurements$cumulative_kwh, prediction$minute))

png(filename=fname, width=1200, height=500, units='px', pointsize=12, bg='white')
# Set up empty plot
plot(measurements$plotstamp, measurements$cumulative_kwh, type='l', col='white', ylim=c(0,ymax), xlab='', ylab='Cumulative kwh')
years <- seq(min(measurements$year), max(measurements$year))
ghostyears <- length(years) - 1
ghostcolors <- grey.colors(ghostyears,start=0.9, end=0.5)
for (i in seq(1, length(years))){
    plotdata <- subset(measurements, measurements$year == years[i])
    if (years[i] < max(years)) {
        linecolor <- ghostcolors[i]
    } else {
        linecolor <- 'red'
    }
    lines(plotdata$plotstamp, plotdata$cumulative_kwh, col=linecolor, lwd=1.5)
}
lines(prediction$time, prediction$minute, col='blue4', lty=2)
lines(predline, col='red', lty=2, lwd=1.5)
abline(h=kwhavg, col='orange')
leg.txt <- c(years[1], '. . .', years[ghostyears], years[length(years)], "predicted total kwh", "average kwh")
leg.lty <- c(1, 1, 1, 1, 2, 1)
leg.col <- c(ghostcolors[1], 'white', ghostcolors[ghostyears], 'red', 'blue4', 'orange')
legend("bottomright", legend=leg.txt, col=leg.col, lty=leg.lty, inset=0.01)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
