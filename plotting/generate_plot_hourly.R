if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/home/jessebishop/scripts/electricity_logging/barplot.R')

query <- "SELECT hour AS label, kwh, kwh_avg, complete FROM electricity_usage_hourly WHERE NOT hour = date_part('hour', CURRENT_TIMESTAMP - interval '4 hours') ORDER BY timestamp;"
res <- dbGetQuery(con, query)

#query2 <- "SELECT date_part('hour', CURRENT_TIMESTAMP - interval '4 hours') AS label, akwh AS kwh, kwh_avg, 'no'::text AS complete FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS akwh FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '4 hours' - interval '1 hour' AND date_part('hour', measurement_time) = date_part('hour', CURRENT_TIMESTAMP - interval '4 hours')) AS x, electricity_usage_hourly WHERE hour = date_part('hour', CURRENT_TIMESTAMP - interval '4 hours');"
query2 <- "SELECT date_part('hour', CURRENT_TIMESTAMP - interval '4 hours') AS label, increment_usage('electricity_usage_hourly', 'hour') AS kwh, kwh_avg, complete FROM electricity_usage_hourly WHERE hour = date_part('hour', CURRENT_TIMESTAMP - interval '4 hours');"
res2 <- dbGetQuery(con, query2)

res <- rbind(res, res2)
#res$col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
#res$col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410

# Do some sunrise and sunset calculations
today <- Sys.Date()
yesterday <- today - 1
currenthour <- res$label[24]
query3 <- paste("SELECT sunrise, sunset FROM astronomy_data WHERE date = '", today, "';", sep="")
res3 <- dbGetQuery(con, query3)
risehour <- as.numeric(strftime(strptime(res3$sunrise, format='%H:%M:%S'), format="%H"))
sethour <- as.numeric(strftime(strptime(res3$sunset, format='%H:%M:%S'), format="%H"))
if (risehour > currenthour) {
    query4 <- paste("SELECT sunrise FROM astronomy_data WHERE date = '", yesterday, "';", sep="")
    sunrise <- dbGetQuery(con, query4)[1,1]
} else {
    sunrise <- res3$sunrise
}
if (sethour > currenthour) {
    query4 <- paste("SELECT sunset FROM astronomy_data WHERE date = '", yesterday, "';", sep="")
    sunset <- dbGetQuery(con, query4)[1,1]
} else {
    sunset <- res3$sunset
}


fname <- '/var/www/electricity/hourly.png'
title <- "Electricity Used in the Last Day"
label.x <- "Hour"
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$hour, col=res$col)
bp(res, title, label.x, label.y, sunrise, sunset)
dev.off()

system(paste("scp", fname, "75.126.173.130:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)