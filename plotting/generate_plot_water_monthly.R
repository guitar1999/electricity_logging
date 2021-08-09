if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/Users/jbishop/.rconfig.R')
}

source('/Users/jbishop/git/electricity_logging/plotting/barplot.R')

query <- "SELECT label, gallons AS gallons, gallons_avg AS gallons_avg, complete FROM water_plotting.water_monthly_plot_view;"
res <- dbGetQuery(con, query)

res$gallons <- res$gallons / 1000
res$gallons_avg <- res$gallons_avg / 1000

fname <- '/tmp/water_monthly.png'
title <- "Water Extracted in the Last Year"
label.x <- "Month"
label.y <- "Thousand Gallons"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$gallons, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
