if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}

source('/home/jessebishop/scripts/electricity_logging/barplot.R')

query <- "SELECT doy AS label, kwh, kwh_avg, complete FROM electricity_usage_doy WHERE NOT doy = date_part('doy', CURRENT_TIMESTAMP) AND timestamp >= CURRENT_TIMESTAMP - interval '29 days' AND NOT timestamp IS NULL ORDER BY timestamp;"
res <- dbGetQuery(con, query)

#query2 <- "SELECT date_part('doy', CURRENT_TIMESTAMP) AS label, akwh AS kwh, kwh_avg, 'no'::text AS complete FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS akwh FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - (date_part('hour', CURRENT_TIMESTAMP) * 3600 + date_part('minute', CURRENT_TIMESTAMP) * 60 + date_part('second', CURRENT_TIMESTAMP)) * interval '1 second') AS x, electricity_usage_doy WHERE doy = date_part('doy', CURRENT_TIMESTAMP);"
query2 <- "SELECT date_part('doy', CURRENT_TIMESTAMP) AS label, increment_usage('electricity_usage_doy', 'doy') AS kwh, kwh_avg, complete FROM electricity_usage_doy WHERE doy = date_part('doy', CURRENT_TIMESTAMP);"
res2 <- dbGetQuery(con, query2)

res <- rbind(res, res2)
res$jday <- res$label
today <- Sys.Date()
jday <- format(today, '%j')
year.this <- format(today, '%Y')
year.last <- as.numeric(year.this) - 1
res$label <- format(as.Date(res$label - 1, origin=paste(ifelse(res$label <= jday, year.this, year.last), '-01-01', sep='')), '%b-%d')
#res$col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
#res$col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410
#res$col[is.na(res$col) == TRUE] <- 'lightgoldenrod'

fname <- '/var/www/electricity/daily.png'
title <- "Electricity Used in the Last Month"
label.x <- ""
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$doy, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "75.126.173.130:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
