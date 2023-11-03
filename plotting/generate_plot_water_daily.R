if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/barplot.R', sep=''))

query <- "SELECT label, gallons AS gallons, previous_year AS gallons_avg, complete FROM water_plotting.water_daily_plot_view WHERE row_number < 31;"
res <- dbGetQuery(con, query)

res$jday <- res$label
today <- Sys.Date()
jday <- format(today, '%j')
year.this <- format(today, '%Y')
year.last <- as.numeric(year.this) - 1

fname <- '/tmp/water_daily.png'
title <- "Water Extracted in the Last Month"
label.x <- ""
label.y <- "Gallons"
plotlimit <- 1440

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$gallons, names.arg=res$label, col='orange', las=2, main=title, ylab=label.y)
bp(res, title, label.x, label.y, NULL, NULL, plotlimit)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

