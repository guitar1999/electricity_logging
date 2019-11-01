if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}


query <- "select watts_ch1 + watts_ch2 AS watts, watts_ch3, measurement_time from electricity_measurements where measurement_time > (CURRENT_TIMESTAMP) - ((date_part('minute', (CURRENT_TIMESTAMP)) + 60) * interval '1 minute') - (date_part('second', (CURRENT_TIMESTAMP)) * interval '1 second') ORDER BY measurement_time;"
res <- dbGetQuery(con, query)

fname <- '/var/www/electricity/last_hours.png'
mintime <- min(res$measurement_time)
maxtime <- max(res$measurement_time)
maxwatts <- max(res$watts, res$watts_ch3)
if (maxwatts - min(res$watts) < 6000) {
    vseq <- seq(0, maxwatts, ifelse(maxwatts > 4000, 500, ifelse(maxwatts > 1000, 200, 100)))
    vlab <- vseq
    ymin <- 0
} else {
    vseq <- log10(c(1,10,50,100,250,500,750,1000,2500,5000,7500,10000))
    vlab <- 10^vseq
    maxwatts <- log10(maxwatts)
    res$watts <- ifelse(res$watts > 0, log10(res$watts), 0)
    res$watts_ch3 <- ifelse(res$watts_ch3 > 0, log10(res$watts_ch3), 0)
    ymin <- min(c(min(res$watts),min(res$watts_ch3, na.rm = TRUE)))
}

hseq <- seq(mintime, mintime + 7200, 600)

# Do some sunrise and sunset calculations
today <- Sys.Date()
query2 <- paste("SELECT (date || ' ' || sunrise)::timestamp AS sunrise, (date || ' ' || sunset)::timestamp AS sunset FROM astronomy_data WHERE date = '", today, "';", sep="")
res2 <- dbGetQuery(con, query2)


png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
plot(res$measurement_time, res$watts, type='l', col='white', xlim=c(mintime, mintime + 7200), ylim=c(ymin,maxwatts), xlab="Time", ylab="Watts", main=paste("Electricity Usage since ", mintime), xaxt='n', yaxt='n')
axis(side=1, at=hseq, labels=substr(hseq, 12, 16))
axis(side=2, at=vseq, labels=vlab, las=1)
abline(v=mintime + 3600, col='black')
abline(h=vseq, col='grey', lty=3)
abline(v=res2$sunrise, lty=2, col='orange')
abline(v=res2$sunset, lty=2, col='orange')
lines(res$measurement_time, res$watts, col='rosybrown', lwd=1.5)
lines(res$measurement_time, res$watts_ch3, col='orange', lwd=1.5)
leg.txt <- c('HVAC', 'Utility Power')
leg.col <- c('orange', 'rosybrown')
legend('topright', legend=leg.txt, col=leg.col, lty=c(1,1), inset=0.01)
dev.off()

system(paste("scp", fname, paste(webhost, ":/home/jessebishop/webapps/htdocs/home/frompi/electricity2/", sep=""), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
