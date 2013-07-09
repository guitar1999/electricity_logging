library(RPostgreSQL)
source('/home/jessebishop/scripts/electricity_logging/barplot.R')
con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")

query <- "SELECT doy AS label, kwh, kwh_avg, complete FROM electricity_usage_doy WHERE NOT doy = date_part('doy', CURRENT_TIMESTAMP) AND doy >= date_part('doy', CURRENT_TIMESTAMP - interval '29 days') AND NOT timestamp IS NULL ORDER BY timestamp;"
res <- dbGetQuery(con, query)

query2 <- "SELECT date_part('doy', CURRENT_TIMESTAMP) AS label, akwh AS kwh, kwh_avg, 'no'::text AS complete FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS akwh FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - (date_part('hour', CURRENT_TIMESTAMP) * 3600 + date_part('minute', CURRENT_TIMESTAMP) * 60 + date_part('second', CURRENT_TIMESTAMP)) * interval '1 second') AS x, electricity_usage_doy WHERE doy = date_part('doy', CURRENT_TIMESTAMP);"
res2 <- dbGetQuery(con, query2)

res <- rbind(res, res2)
#res$col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
#res$col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410
#res$col[is.na(res$col) == TRUE] <- 'lightgoldenrod'

fname <- '/var/www/electricity/daily.png'
title <- "Electricity Usage By Day"
label.x <- "Day"
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$doy, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '))
