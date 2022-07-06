if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/barplot.R', sep=''))

query <- "SELECT label, gallons AS gallons, gallons_avg AS gallons_avg, complete FROM water_plotting.water_hourly_dow_season_plot_view;"
res <- dbGetQuery(con, query)

# Do some sunrise and sunset calculations
today <- Sys.Date()
yesterday <- today - 1
currenthour <- res$label[24]
query3 <- paste("SELECT sunrise, sunset FROM astronomy_data WHERE date = '", today, "';", sep="")
res3 <- dbGetQuery(con, query3)
risehour <- as.numeric(strftime(strptime(res3$sunrise, format='%H:%M:%S'), format="%H"))
sethour <- as.numeric(strftime(strptime(res3$sunset, format='%H:%M:%S'), format="%H"))
if (risehour > currenthour) {
    query4 <- paste("SELECT sunrise FROM astronomy_data WHERE date = '", yesterday, "';", sep="")
    sunrise <- dbGetQuery(con, query4)[1,1]
} else {
    sunrise <- res3$sunrise
}
if (sethour > currenthour) {
    query4 <- paste("SELECT sunset FROM astronomy_data WHERE date = '", yesterday, "';", sep="")
    sunset <- dbGetQuery(con, query4)[1,1]
} else {
    sunset <- res3$sunset
}

# res$gallons <- res$gallons / 1000
# res$gallons_avg <- res$gallons_avg / 1000

fname <- '/tmp/water_hourly_dow_season.png'
title <- "Water Extracted in the Last Day"
label.x <- "Hour"
label.y <- "Gallons"
plotlimit <- 60

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$gallons, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
bp(res, title, label.x, label.y, sunrise, sunset, plotlimit)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

