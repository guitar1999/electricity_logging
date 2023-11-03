if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/barplot.R', sep=''))

query <- "SELECT label, gallons AS gallons, previous_yeartodate_gallons AS gallons_avg, complete FROM water_plotting.water_yearly_plot_view;"
res <- dbGetQuery(con, query)

res$gallons <- res$gallons / 1000
res$gallons_avg <- res$gallons_avg / 1000

fname <- '/tmp/water_yearly.png'
title <- "Water Extracted By Year"
label.x <- "Year"
label.y <- "Thousand Gallons"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#b <- barplot(res$gallons, names.arg=res$label, col='orange', las=1, main=title, ylab=label.y)
#points(b, res$gallons_avg)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

