if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "SELECT to_char(to_timestamp(u.month::text, 'MM'), 'Mon') || '-' || to_char(u.day, '09') AS label, kwh, previous_year AS kwh_avg, complete FROM electricity_usage_doy u INNER JOIN electricity_statistics_doy s ON u.month=s.month AND u.day=s.day WHERE (NOT u.month = date_part('month', CURRENT_TIMESTAMP) OR NOT u.day = date_part('day', CURRENT_TIMESTAMP)) AND ((is_leapyear(date_part('year', CURRENT_TIMESTAMP)::integer) OR is_leapyear(date_part('year', CURRENT_TIMESTAMP)::integer - 1)) OR ( NOT u.month = 2 OR NOT u.day = 29)) AND NOT u.updated IS NULL ORDER BY u.updated;"
res <- dbGetQuery(con, query)

query2 <- "SELECT to_char(to_timestamp(u.month::text, 'MM'), 'Mon') || '-' || to_char(u.day, '09') AS label, kwh, previous_year AS kwh_avg, complete FROM electricity_usage_doy u INNER JOIN electricity_statistics_doy s ON u.month=s.month AND u.day=s.day WHERE u.month = date_part('month', CURRENT_TIMESTAMP) AND u.day = date_part('day', CURRENT_TIMESTAMP);"
res2 <- dbGetQuery(con, query2)

res <- rbind(res, res2)
res$jday <- res$label

fname <- '/var/www/electricity/daily_1year.png'
title <- "Electricity Used Daily"
label.x <- ""
label.y <- "kwh"

png(filename=fname, width=10240, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$doy, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "75.126.173.130:/home/jessebishop/webapps/htdocs/home/frompi/electricity2/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
