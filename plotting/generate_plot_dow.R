if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "SELECT u.day_of_week AS label, u.dow, u.kwh, s.kwh_avg, u.complete FROM electricity_usage_dow u INNER JOIN electricity_statistics_dow s ON u.dow=s.dow WHERE NOT u.dow = date_part('dow', CURRENT_TIMESTAMP) ORDER BY u.updated;"
res <- dbGetQuery(con, query)

#query2 <- "SELECT day_of_week AS label, date_part('dow', CURRENT_TIMESTAMP) AS dow, akwh AS kwh, kwh_avg, 'no'::text AS complete FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS akwh FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '1 day' AND date_part('dow', measurement_time) = date_part('dow', CURRENT_TIMESTAMP)) AS x, electricity_usage_dow WHERE dow = date_part('dow', CURRENT_TIMESTAMP);"
query2 <- "SELECT u.day_of_week AS label, date_part('dow', CURRENT_TIMESTAMP) AS dow, increment_usage('electricity_usage_dow', 'dow') AS kwh, s.kwh_avg, u.complete FROM electricity_usage_dow u INNER JOIN electricity_statistics_dow s ON u.dow=s.dow WHERE u.dow = date_part('dow', CURRENT_TIMESTAMP);"
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

system(paste("scp", fname, paste(webhost, ":/home/jessebishop/webapps/htdocs/home/frompi/electricity2/", sep=""), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
