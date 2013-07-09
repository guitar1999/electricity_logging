library(RPostgreSQL)
con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")

query <- "select watts_ch1 + watts_ch2 AS watts, measurement_time from electricity_measurements where measurement_time > CURRENT_TIMESTAMP - ((date_part('minute', CURRENT_TIMESTAMP) + 60) * interval '1 minute') - (date_part('second', CURRENT_TIMESTAMP) * interval '1 second');"
res <- dbGetQuery(con, query)

fname <- '/var/www/electricity/last_hours.png'
mintime <- min(res$measurement_time)
maxtime <- max(res$measurement_time)
maxwatts <- max(res$watts)
if (maxwatts - min(res$watts) < 2000) {
    vseq <- seq(0, maxwatts, ifelse(maxwatts > 1000, 200, 100))
    vlab <- vseq
} else {
    vseq <- log10(c(1,10,50,100,250,500,750,1000,2500,5000,7500,10000))
    vlab <- 10^vseq
    maxwatts <- log10(maxwatts)
    res$watts <- log10(res$watts)
}

hseq <- seq(mintime, mintime + 7200, 600)

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
plot(res$measurement_time, res$watts, type='l', col='white', xlim=c(mintime, mintime + 7200), ylim=c(0,maxwatts), xlab="Time", ylab="Watts", main=paste("Electricity Usage since ", mintime), xaxt='n', yaxt='n')
axis(side=1, at=hseq, labels=substr(hseq, 12, 16))
axis(side=2, at=vseq, labels=vlab, las=1)
abline(v=mintime + 3600, col='black')
abline(h=vseq, col='grey', lty=2)
lines(res$measurement_time, res$watts, col='rosybrown')
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '))
