if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

#query <- "SELECT to_char(to_timestamp(u.month::text, 'MM'), 'Mon') || '-' || to_char(u.day, '09') AS label, kwh, previous_year AS kwh_avg, complete FROM electricity_usage_doy u INNER JOIN electricity_statistics_doy s ON u.month=s.month AND u.day=s.day WHERE (NOT u.month = date_part('month', CURRENT_TIMESTAMP) OR NOT u.day = date_part('day', CURRENT_TIMESTAMP)) AND ((is_leapyear(date_part('year', CURRENT_TIMESTAMP)::integer) OR is_leapyear(date_part('year', CURRENT_TIMESTAMP)::integer - 1)) OR ( NOT u.month = 2 OR NOT u.day = 29)) AND NOT u.updated IS NULL ORDER BY u.updated;"
query <- "WITH dates AS (SELECT generate_series::DATE AS d FROM generate_series(CURRENT_TIMESTAMP, CURRENT_TIMESTAMP - CASE WHEN is_leapyear(DATE_PART('year', CURRENT_TIMESTAMP)::INTEGER) THEN interval '365 days' ELSE interval '364 days' END, '-1 day')), cur_kwh AS (SELECT CURRENT_TIMESTAMP::DATE d, increment_usage('electricity_usage_doy', CASE WHEN is_leapyear(DATE_PART('year', CURRENT_TIMESTAMP)::INTEGER) THEN 'doy_leap' ELSE 'doy_noleap' END) AS kwh) SELECT to_char(to_timestamp(DATE_PART('month', o.d)::text, 'MM'), 'Mon') || ' -' || to_char(DATE_PART('day', o.d), '09') AS label, CASE WHEN o.d = CURRENT_TIMESTAMP::DATE THEN ck.kwh ELSE CASE WHEN c.kwh IS NULL THEN u.kwh ELSE c.kwh END END AS kwh, c1.kwh AS kwh_avg, CASE WHEN c.kwh IS NULL THEN 'no'::TEXT ELSE 'yes'::TEXT END AS complete FROM dates o INNER JOIN electricity.electricity_usage_doy u ON DATE_PART('doy', o.d)=CASE WHEN is_leapyear(DATE_PART('year', o.d)::INTEGER) THEN u.doy_leap ELSE u.doy_noleap END LEFT JOIN electricity_cmp.cmp_electricity_sums_daily_view c ON c.sum_date=o.d LEFT JOIN cur_kwh ck ON ck.d=o.d LEFT JOIN electricity_cmp.cmp_electricity_sums_daily_view c1 ON c1.sum_date=o.d - interval '1 year';"
res <- dbGetQuery(con, query)

#query2 <- "SELECT to_char(to_timestamp(u.month::text, 'MM'), 'Mon') || '-' || to_char(u.day, '09') AS label, kwh, previous_year AS kwh_avg, complete FROM electricity_usage_doy u INNER JOIN electricity_statistics_doy s ON u.month=s.month AND u.day=s.day WHERE u.month = date_part('month', CURRENT_TIMESTAMP) AND u.day = date_part('day', CURRENT_TIMESTAMP);"
#res2 <- dbGetQuery(con, query2)

#res <- rbind(res, res2)
res$jday <- res$label

fname <- '/var/www/electricity/daily_1year.png'
title <- "Electricity Used Daily"
label.x <- ""
label.y <- "kwh"

png(filename=fname, width=10240, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$doy, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "207.38.86.222:/home/jessebishop/webapps/htdocs/home/frompi/electricity2/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
