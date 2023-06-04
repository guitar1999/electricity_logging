if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/barplot.R', sep=''))

query <- "SELECT label, gallons AS gallons, gallons_avg AS gallons_avg, complete FROM water_plotting.water_dow_season_plot_view;"
res <- dbGetQuery(con, query)

fname <- '/tmp/water_dow_season.png'
title <- "Water Extracted in the Last Week"
label.x <- "Day"
label.y <- "Gallons"
plotlimit <- 1440

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
bp(res, title, label.x, label.y, NULL, NULL, plotlimit)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
