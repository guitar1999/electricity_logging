if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "SELECT u.month AS label, u.kwh, s.kwh_avg, u.complete FROM electricity_usage_monthly u INNER JOIN electricity_statistics_monthly s ON u.month=s.month WHERE NOT u.month = date_part('month', CURRENT_TIMESTAMP) AND NOT u.updated IS NULL ORDER BY u.updated;"
res <- dbGetQuery(con, query)

#query2 <- "SELECT date_part('month', CURRENT_TIMESTAMP) AS label, akwh AS kwh, kwh_avg, 'no'::text AS complete FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS akwh FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '1 month' AND date_part('month', measurement_time) = date_part('month', CURRENT_TIMESTAMP)) AS x, electricity_usage_monthly WHERE month = date_part('month', CURRENT_TIMESTAMP);"
query2 <- "SELECT date_part('month', CURRENT_TIMESTAMP) AS label, increment_usage('electricity_usage_monthly', 'month') AS kwh, s.kwh_avg, u.complete FROM electricity_usage_monthly u INNER JOIN electricity_statistics_monthly s ON u.month=s.month WHERE u.month = date_part('month', CURRENT_TIMESTAMP);"
res2 <- dbGetQuery(con, query2)

res <- rbind(res, res2)
#res$col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
#res$col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410
#res$col[is.na(res$col) == TRUE] <- 'lightgoldenrod'

fname <- '/var/www/electricity/monthly.png'
title <- "Electricity Used in the Last Year"
label.x <- "Month"
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$month, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "75.126.173.130:/home/jessebishop/webapps/htdocs/home/frompi/electricity2/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
