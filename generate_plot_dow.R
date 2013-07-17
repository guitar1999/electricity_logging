library(RPostgreSQL)
source('/home/jessebishop/scripts/electricity_logging/barplot.R')
con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")

query <- "SELECT day_of_week AS label, dow, kwh, kwh_avg, complete FROM electricity_usage_dow WHERE NOT dow = date_part('dow', CURRENT_TIMESTAMP) ORDER BY timestamp;"
res <- dbGetQuery(con, query)

query2 <- "SELECT day_of_week AS label, date_part('dow', CURRENT_TIMESTAMP) AS dow, akwh AS kwh, kwh_avg, 'no'::text AS complete FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS akwh FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '1 day' AND date_part('dow', measurement_time) = date_part('dow', CURRENT_TIMESTAMP)) AS x, electricity_usage_dow WHERE dow = date_part('dow', CURRENT_TIMESTAMP);"
res2 <- dbGetQuery(con, query2)
res <- rbind(res, res2)
#res$col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
#res$col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410
#res$pcol[res$kwh > res$kwh_avg] <- 'firebrick'
#res$pcol[res$kwh <= res$kwh_avg] <- 'darkgoldenrod'

fname <- '/var/www/electricity/dow.png'
title <- "Electricity Used in the Last Week"
label.x <- "Day"
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$day_of_week, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '))
