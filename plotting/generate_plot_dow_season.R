if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "WITH dates AS (SELECT generate_series::DATE AS d FROM generate_series(CURRENT_TIMESTAMP, CURRENT_TIMESTAMP - interval '6 days', '-1 day')) SELECT u.day_of_week AS label, u.dow, CASE WHEN c.kwh IS NULL THEN u.kwh ELSE c.kwh END AS kwh, s.kwh_avg, CASE WHEN c.kwh IS NULL THEN 'no'::TEXT ELSE 'yes'::TEXT END AS complete FROM dates o INNER JOIN electricity.electricity_usage_dow u ON DATE_PART('dow', o.d)=u.dow LEFT JOIN electricity_cmp.cmp_electricity_sums_daily_view c ON c.sum_date=o.d INNER JOIN weather_data.meteorological_season m ON DATE_PART('doy', o.d)=m.doy INNER JOIN electricity_cmp.cmp_electricity_statistics_dow s ON u.dow=s.dow AND m.season=s.season ORDER BY o.d;"
res <- dbGetQuery(con, query)


fname <- '/var/www/electricity/dow_season.png'
title <- "Electricity Used in the Last Week (Season Averaging)"
label.x <- "Day"
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$day_of_week, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "75.126.173.130:/home/jessebishop/webapps/htdocs/home/frompi/electricity2/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
