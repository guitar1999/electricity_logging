if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/home/jessebishop/scripts/electricity_logging/barplot.R')

query <- "SELECT u.day_of_week AS label, u.dow, u.kwh, s.kwh_avg AS kwh_avg, u.complete FROM (electricity_usage_dow u INNER JOIN meteorological_season m ON date_part('doy', CASE WHEN date_part('hour', u.timestamp) = 0 AND date_part('minute', u.timestamp) < 2 THEN u.timestamp - interval '1 day' ELSE u.timestamp END) = m.doy) INNER JOIN energy_statistics.electricity_statistics_dow_season s ON u.dow=s.dow AND s.season=m.season WHERE NOT u.dow = date_part('dow', CURRENT_TIMESTAMP - interval '4 hours') ORDER BY u.timestamp;"
res <- dbGetQuery(con, query)

#query2 <- "SELECT day_of_week AS label, date_part('dow', CURRENT_TIMESTAMP - interval '4 hours') AS dow, akwh AS kwh, kwh_avg, 'no'::text AS complete FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS akwh FROM electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - interval '4 hours' - interval '1 day' AND date_part('dow', measurement_time) = date_part('dow', CURRENT_TIMESTAMP - interval '4 hours')) AS x, electricity_usage_dow WHERE dow = date_part('dow', CURRENT_TIMESTAMP - interval '4 hours');"
query2 <- "SELECT day_of_week AS label, date_part('dow', CURRENT_TIMESTAMP - interval '4 hours') AS dow, u.kwh, s.kwh_avg AS kwh_avg, complete FROM electricity_usage_dow u INNER JOIN energy_statistics.electricity_statistics_dow_season s ON u.dow=s.dow WHERE u.dow = date_part('dow', CURRENT_TIMESTAMP - interval '4 hours') AND s.season = (SELECT season FROM meteorological_season WHERE doy = date_part('doy', CURRENT_TIMESTAMP - interval '4 hours'));"
res2 <- dbGetQuery(con, query2)
res <- rbind(res, res2)
#res$col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
#res$col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410
#res$pcol[res$kwh > res$kwh_avg] <- 'firebrick'
#res$pcol[res$kwh <= res$kwh_avg] <- 'darkgoldenrod'

fname <- '/var/www/electricity/dow_season.png'
title <- "Electricity Used in the Last Week (Season Averaging)"
label.x <- "Day"
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$day_of_week, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "75.126.173.130:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)