if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/home/jessebishop/.rconfig.R')
}

source('/usr/local/electricity_logging/plotting/barplot.R')

query <- "SELECT label, kwh, kwh_avg, complete FROM electricity_plotting.electricity_dow_season;"
res <- dbGetQuery(con, query)

fname <- '/var/www/electricity/dow_season.png'
title <- "Electricity Used in the Last Week (Season Averaging)"
label.x <- "Day"
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$day_of_week, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, paste(webhost, ":/home/jessebishop/webapps/htdocs/home/frompi/electricity2/", sep=""), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
