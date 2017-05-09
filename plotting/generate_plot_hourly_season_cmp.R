if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "WITH opdate AS (SELECT MAX(sum_date) AS plot_date FROM electricity_cmp.cmp_electricity_sums_hourly_view) SELECT su.hour AS label, su.kwh, SUM(st.kwh_avg * st.count) / SUM(st.count) AS kwh_avg, 'yes'::TEXT AS complete FROM opdate, electricity_cmp.cmp_electricity_sums_hourly_view su INNER JOIN electricity_cmp.cmp_electricity_statistics_hourly st ON su.hour=st.hour INNER JOIN weather_data.meteorological_season m ON m.doy=DATE_PART('doy', su.sum_date) WHERE su.sum_date = opdate.plot_date AND st.season = m.season GROUP BY su.hour, su.kwh ORDER BY su.hour;"
res <- dbGetQuery(con, query)

# Do some sunrise and sunset calculations
query <- "SELECT MAX(sum_date) AS plot_date FROM electricity_cmp.cmp_electricity_sums_hourly_view;"
today <- dbGetQuery(con, query)$plot_date
yesterday <- today - 1
currenthour <- res$label[length(res$label)]
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

fname <- '/var/www/electricity/hourly_season_cmp.png'
title <- paste("Electricity Used on", today, "(Seasonal Averaging)")
label.x <- "Hour"
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$hour, col=res$col)
bp(res, title, label.x, label.y, sunrise, sunset)
dev.off()

system(paste("scp", fname, paste(webhost, ":/home/jessebishop/webapps/htdocs/home/frompi/electricity2/", sep=""), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
