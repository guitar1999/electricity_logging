if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

#query <- "SELECT to_char(to_timestamp(u.month::text, 'MM'), 'Mon') || '-' || to_char(u.day, '09') AS label, u.kwh, s.previous_year AS kwh_avg, u.complete FROM electricity_usage_doy u INNER JOIN electricity_statistics_doy s ON u.month=s.month AND u.day=s.day WHERE (NOT u.month = date_part('month', CURRENT_TIMESTAMP) OR NOT u.day = date_part('day', CURRENT_TIMESTAMP)) AND u.updated >= CURRENT_TIMESTAMP - interval '29 days' AND NOT u.updated IS NULL ORDER BY u.updated;"
#res <- dbGetQuery(con, query)

#query2 <- "SELECT to_char(to_timestamp(u.month::text, 'MM'), 'Mon') || '-' || to_char(u.day, '09') AS label, increment_usage('electricity_usage_doy', CASE WHEN is_leapyear(date_part('year', CURRENT_TIMESTAMP)::integer) THEN 'doy_leap' ELSE 'doy_noleap' END) AS kwh, previous_year AS kwh_avg, complete FROM electricity_usage_doy u INNER JOIN electricity_statistics_doy s ON u.month=s.month AND u.day=s.day WHERE u.month = date_part('month', CURRENT_TIMESTAMP) AND u.day = date_part('day', CURRENT_TIMESTAMP);"
#res2 <- dbGetQuery(con, query2)

#res <- rbind(res, res2)

# New Full Query
#SELECT s.sum_date, s.dow, s.kwh, st.kwh_avg, st.count, s1.kwh AS last_year FROM cmp_electricity_sums_daily_view s INNER JOIN cmp_electricity_statistics_doy st ON DATE_PART('month', s.sum_date) = st.month AND DATE_PART('day', s.sum_date) = st.day LEFT JOIN cmp_electricity_sums_daily_view s1 ON DATE_PART('year', s.sum_date) - 1 = DATE_PART('year', s1.sum_date) AND DATE_PART('month', s.sum_date) = DATE_PART('month', s1.sum_date) AND DATE_PART('day', s.sum_date) = DATE_PART('day', s1.sum_date) ORDER BY s.sum_date LIMIT 30;

query <- "SELECT to_char(to_timestamp(DATE_PART('month', s.sum_date)::text, 'MM'), 'Mon') || '-' || to_char(DATE_PART('day', s.sum_date), '09') AS label, s.kwh, s1.kwh::NUMERIC AS kwh_avg, 'Yes' AS complete FROM cmp_electricity_sums_daily_view s LEFT JOIN cmp_electricity_sums_daily_view s1 ON DATE_PART('year', s.sum_date) - 1 = DATE_PART('year', s1.sum_date) AND DATE_PART('month', s.sum_date) = DATE_PART('month', s1.sum_date) AND DATE_PART('day', s.sum_date) = DATE_PART('day', s1.sum_date) WHERE s.sum_date >= (SELECT MAX(sum_date) FROM cmp_electricity_sums_daily_view) - INTERVAL '30 days' ORDER BY s.sum_date  LIMIT 30;"
res <- dbGetQuery(con, query)

res$jday <- res$label # Fake it until I fix barplot function to take las as an argument

fname <- '/var/www/electricity/daily.png'
title <- "Electricity Used in the Last Month"
label.x <- ""
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, "75.126.173.130:/home/jessebishop/webapps/htdocs/home/frompi/electricity2/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
