if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "SELECT label, gallons AS gallons, gallons_avg AS gallons_avg, complete FROM water_plotting.water_dow_plot_view;"
res <- dbGetQuery(con, query)

fname <- '/var/www/electricity/water_dow.png'
title <- "Water Extracted in the Last Week"
label.x <- "Day"
label.y <- "Gallons"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
barplot(res$gallons, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
dev.off()

system(paste("scp", fname, paste(webhost, ":/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=""), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)