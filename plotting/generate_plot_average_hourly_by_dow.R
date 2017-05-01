if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

dd <- data.frame(dow = seq(0,6), day = c('Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'))

query <- "SELECT dow, hour, AVG(kwh) AS kwh FROM (SELECT date_part('dow', measurement_time) AS dow, date_part('hour', measurement_time) AS hour, SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements GROUP BY dow, hour, date_part('doy', measurement_time)) AS x GROUP BY dow, hour;"
res <- dbGetQuery(con, query)

res <- merge(res,dd)

fname <- '/var/www/electricity/average_hourly_by_dow.png'

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
dev.off()
plot(res$hour, res$kwh, col='white', xaxt='n')
axis(side=1, at=seq(0,23), labels=seq(0,23))
for (i in seq(0,6)){
    pdf <- subset(res, res$dow == i)
    lines(pdf$hour, pdf$kwh, col=i+1)
}
legend(0, max(res$kwh) - 100, dd$day, dd$dow)
system(paste("scp", fname, "207.38.86.222:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

