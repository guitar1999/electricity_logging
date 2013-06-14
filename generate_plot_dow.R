library(RPostgreSQL)
con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")

query <- "SELECT dow, day_of_week, kwh, kwh_avg, complete FROM electricity_usage_dow WHERE NOT dow = date_part('dow', CURRENT_TIMESTAMP) ORDER BY timestamp;"
res <- dbGetQuery(con, query)

query2 <- "SELECT date_part('dow', CURRENT_TIMESTAMP) AS dow, day_of_week, akwh AS kwh, kwh_avg, 'no'::text AS complete FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS akwh FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '1 day' AND date_part('dow', measurement_time) = date_part('dow', CURRENT_TIMESTAMP)) AS x, electricity_usage_dow WHERE dow = date_part('dow', CURRENT_TIMESTAMP);"
res2 <- dbGetQuery(con, query2)
print(res2)
res <- rbind(res, res2)
res$col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
res$col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410


fname <- '/var/www/electricity/dow.png'
#maxwatts <- max(res$watts)
#vseq <- seq(0, maxwatts, ifelse(maxwatts > 1000, 200, 100))
#hseq <- seq(mintime, mintime + 7200, 600)

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$kwh, names.arg=res$day_of_week, col=res$col)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '))
