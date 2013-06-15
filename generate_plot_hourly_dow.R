library(RPostgreSQL)
source('/home/jessebishop/scripts/electricity_logging/barplot.R')
con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")

query <- "SELECT hour, kwh, kwh_avg, kwh_avg_dow, complete FROM electricity_usage_hourly WHERE NOT hour = date_part('hour', CURRENT_TIMESTAMP) ORDER BY timestamp;"
res <- dbGetQuery(con, query)

query2 <- "SELECT date_part('hour', CURRENT_TIMESTAMP) AS hour, akwh AS kwh, kwh_avg, kwh_avg_dow, 'no'::text AS complete FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS akwh FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '1 hour' AND date_part('hour', measurement_time) = date_part('hour', CURRENT_TIMESTAMP)) AS x, electricity_usage_hourly WHERE hour = date_part('hour', CURRENT_TIMESTAMP);"
res2 <- dbGetQuery(con, query2)

res <- rbind(res, res2)
#res$col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
#res$col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410
res$kwh_avg <- res$kwh_avg_dow

fname <- '/var/www/electricity/hourly_dow.png'
#maxwatts <- max(res$watts)
#vseq <- seq(0, maxwatts, ifelse(maxwatts > 1000, 200, 100))
#hseq <- seq(mintime, mintime + 7200, 600)

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$hour, col=res$col)
bp(res$kwh, res$hour, res$kwh_avg)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '))
