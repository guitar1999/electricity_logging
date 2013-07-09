library(RPostgreSQL)
source('/home/jessebishop/scripts/electricity_logging/barplot.R')
con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")

query <- "SELECT year AS label, kwh, complete FROM electricity_usage_yearly WHERE NOT year = date_part('year', CURRENT_TIMESTAMP) AND NOT timestamp IS NULL ORDER BY timestamp;"
res <- dbGetQuery(con, query)

query2 <- "SELECT date_part('year', CURRENT_TIMESTAMP) AS label, akwh AS kwh, 'no'::text AS complete FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS akwh FROM electricity_measurements WHERE date_part('year', measurement_time) = date_part('year', CURRENT_TIMESTAMP)) AS x;"
res2 <- dbGetQuery(con, query2)

res <- rbind(res, res2)
#res$col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
#res$col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410
#res$col[is.na(res$col) == TRUE] <- 'lightgoldenrod'

fname <- '/var/www/electricity/yearly.png'
title <- "Electricity Usage By Year"
label.x <- "Year"
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$month, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '))
