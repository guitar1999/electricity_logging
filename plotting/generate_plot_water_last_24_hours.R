if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}


query <- "SELECT watts_water_pump, measurement_time FROM electricity_iotawatt.electricity_measurements WHERE measurement_time > CURRENT_TIMESTAMP - INTERVAL '22 HOURS' - ((DATE_PART('MINUTE', CURRENT_TIMESTAMP) + 60) * INTERVAL '1 MINUTE') - (DATE_PART('SECOND', CURRENT_TIMESTAMP) * INTERVAL '1 SECOND') AND watts_water_pump IS NOT NULL ORDER BY measurement_time;"
res <- dbGetQuery(con, query)
res$watts_water_pump <- res$watts_water_pump * 2

fname <- '/tmp/water_last_24_hours.png'
mintime <- min(res$measurement_time)
maxwatts <- max(100, res$watts_water_pump, na.rm=TRUE)
vseq <- seq(0, maxwatts, ifelse(maxwatts > 1000, 200, 100))
vlab <- vseq
hseq <- seq(mintime, mintime + 86400, 1800)

# Do some sunrise and sunset calculations
today <- Sys.Date()
query2 <- paste("SELECT (date || ' ' || sunrise)::timestamp AS sunrise, (date || ' ' || sunset)::timestamp AS sunset FROM astronomy_data WHERE date = '", today, "';", sep="")
res2 <- dbGetQuery(con, query2)


png(filename=fname, width=10240, height=700, units='px', pointsize=12, bg='white')
plot(res$measurement_time, res$watts_water_pump, type='l', col='white', xlim=c(mintime, mintime + 86400), ylim=c(0,maxwatts), xlab="Time", ylab="Watts", main=paste("Well Pump Electricity Usage since ", mintime), xaxt='n', yaxt='n')
axis(side=1, at=hseq, labels=substr(hseq, 12, 16))
axis(side=2, at=vseq, labels=vlab, las=1)
abline(v=seq(mintime, mintime + 86400, 3600), col='black')
abline(h=vseq, col='grey', lty=2)
abline(v=res2$sunrise, lty=2, col='orange')
abline(v=res2$sunset, lty=2, col='orange')
lines(res$measurement_time, res$watts_water_pump, col='steelblue')
legend('topright', legend=c('Well Pump'), col=c('steelblue'), lty=c(1), inset=0.01)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
