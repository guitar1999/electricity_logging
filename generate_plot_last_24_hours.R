if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")
}


query <- "select watts_ch1, watts_ch2, watts_ch3, measurement_time from electricity_measurements where measurement_time > CURRENT_TIMESTAMP - interval '22 hours' - ((date_part('minute', CURRENT_TIMESTAMP) + 60) * interval '1 minute') - (date_part('second', CURRENT_TIMESTAMP) * interval '1 second');"
res <- dbGetQuery(con, query)
#res$watts <- res$watts_ch1 + res$watts_ch2

fname <- '/var/www/electricity/last_24_hours.png'
mintime <- min(res$measurement_time)
maxtime <- max(res$measurement_time)
maxwatts <- max(rbind(res$watts_ch1, res$watts_ch2))
if (maxwatts - min(rbind(res$watts_ch1, res$watts_ch2)) < 2400) {
    vseq <- seq(0, maxwatts, ifelse(maxwatts > 1000, 200, 100))
    vlab <- vseq
} else {
    vseq <- log10(c(1,10,50,100,250,500,750,1000,2500,5000,7500,10000))
    vlab <- 10^vseq
    maxwatts <- log10(maxwatts)
    res$watts_ch1 <- log10(res$watts_ch1)
    res$watts_ch2 <- log10(res$watts_ch2)
    res$watts_ch3 <- log10(res$watts_ch3)
}

hseq <- seq(mintime, mintime + 86400, 1800)

# Do some sunrise and sunset calculations
today <- Sys.Date()
query2 <- paste("SELECT (date || ' ' || sunrise)::timestamp AS sunrise, (date || ' ' || sunset)::timestamp AS sunset FROM astronomy_data WHERE date = '", today, "';", sep="")
res2 <- dbGetQuery(con, query2)


png(filename=fname, width=10240, height=700, units='px', pointsize=12, bg='white')
plot(res$measurement_time, res$watts_ch1, type='l', col='white', xlim=c(mintime, mintime + 86400), ylim=c(0,maxwatts), xlab="Time", ylab="Watts", main=paste("Electricity Usage since ", mintime), xaxt='n', yaxt='n')
axis(side=1, at=hseq, labels=substr(hseq, 12, 16))
axis(side=2, at=vseq, labels=vlab, las=1)
abline(v=seq(mintime, mintime + 86400, 3600), col='black')
abline(h=vseq, col='grey', lty=2)
abline(v=res2$sunrise, lty=2, col='orange')
abline(v=res2$sunset, lty=2, col='orange')
lines(res$measurement_time, res$watts_ch1, col='red')
lines(res$measurement_time, res$watts_ch2, col='blue')
lines(res$measurement_time, res$watts_ch3, col='orange')
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
