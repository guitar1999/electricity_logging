if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

query <- "SELECT (watts_ch1 + watts_ch2) * tdiff / 1000. / 60 / 60 AS kwh, measurement_time - interval '1 year' AS measurement_time, sum((watts_ch1 + watts_ch2) * tdiff / 1000. / 60 / 60) OVER (ORDER BY measurement_time) AS cumulative_kwh FROM electricity_measurements WHERE date_part('month', measurement_time) = date_part('month', CURRENT_TIMESTAMP) AND date_part('year', measurement_time) = date_part('year', CURRENT_TIMESTAMP) ORDER BY measurement_time;"
current_year <- dbGetQuery(con, query)

query <- "SELECT kwh, measurement_time, cumulative_kwh FROM electricity_month_previous_year ORDER BY measurement_time;"
last_year <- dbGetQuery(con, query)

query <- "SELECT kwh_avg FROM electricity_statistics_monthly WHERE month = date_part('month', CURRENT_TIMESTAMP);"
kwhavg <- dbGetQuery(con, query)

query <- "SELECT time - interval '1 year' AS time, minute FROM prediction_test WHERE date_part('month', time) = date_part('month', current_timestamp) AND minute > 0 ORDER BY time;"
prediction <- dbGetQuery(con, query)

fname <- '/var/www/electricity/month_to_month.png'
pmax <- max(c(last_year$cumulative_kwh, current_year$cumulative_kwh, prediction$minute))

png(filename=fname, width=1200, height=500, units='px', pointsize=12, bg='white')
plot(last_year$measurement_time, last_year$cumulative_kwh, type='l', col='grey', ylim=c(0,pmax), xlab='', ylab='Cumulative kwh')
lines(current_year$measurement_time, current_year$cumulative_kwh, col='red')
lines(prediction$time, prediction$minute, col='blue4', lty=2)
abline(h=kwhavg, col='orange')
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
