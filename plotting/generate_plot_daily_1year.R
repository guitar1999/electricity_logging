if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/Users/jbishop/.rconfig.R')
}

source('/Users/jbishop/git/electricity_logging/plotting/barplot.R')

query <- "SELECT label, kwh, previous_year AS kwh_avg, complete FROM electricity_plotting.electricity_daily WHERE row_number < 366;"
res <- dbGetQuery(con, query)

res$jday <- res$label

fname <- '/tmp/daily_1year.png'
title <- "Electricity Used Daily"
label.x <- ""
label.y <- "kwh"

png(filename=fname, width=10240, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$doy, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
