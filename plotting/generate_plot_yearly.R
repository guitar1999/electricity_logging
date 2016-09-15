if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "SELECT year AS label, kwh, complete FROM cmp_electricity_sums_yearly_view ORDER BY year;"
res <- dbGetQuery(con, query)
if (dim(res)[1] > 0) {
    res$kwh_avg <- NA
}

#query2 <- "SELECT date_part('year', CURRENT_TIMESTAMP) AS label, akwh AS kwh, 'no'::text AS complete FROM (SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS akwh FROM electricity_measurements WHERE date_part('year', measurement_time) = date_part('year', CURRENT_TIMESTAMP)) AS x;"
query2 <- "SELECT date_part('year', CURRENT_TIMESTAMP) AS label, increment_usage('electricity_usage_yearly', 'year') AS kwh, complete FROM electricity_usage_yearly WHERE year = date_part('year', CURRENT_TIMESTAMP);"
res2 <- dbGetQuery(con, query2)

query3 <- "SELECT SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements WHERE measurement_time >= (date_part('year', CURRENT_TIMESTAMP) - 1 || '-01-01 00:00:00')::timestamp with time zone AND measurement_time < CURRENT_TIMESTAMP - interval '1 year';"
ytdkwh <- dbGetQuery(con,query3)
#res2 <- cbind(res2, ytdkwh)

#res <- rbind(res, res2)
#res$col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
#res$col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410
#res$col[is.na(res$col) == TRUE] <- 'lightgoldenrod'

fname <- '/var/www/electricity/yearly.png'
cname <- '/var/www/electricity/yearly.csv'
title <- "Electricity Usage By Year"
label.x <- "Year"
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$month, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "75.126.173.130:/home/jessebishop/webapps/htdocs/home/frompi/electricity2/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

write.table(res, file=cname, row.names=F, col.names=T, quote=F, sep=',')
