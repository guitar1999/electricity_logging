if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "SELECT label, gallons AS gallons, previous_yeartodate_gallons AS gallons_avg, complete FROM water_plotting.water_yearly_plot_view;"
res <- dbGetQuery(con, query)

res$gallons <- res$gallons
res$gallons_avg <- res$gallons_avg

fname <- '/var/www/electricity/water_yearly.png'
title <- "Water Extracted By Year"
label.x <- "Year"
label.y <- "Gallons"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#b <- barplot(res$gallons, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
#points(b, res$gallons_avg)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, paste(webhost, ":/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=""), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

