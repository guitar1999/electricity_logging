if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source('/Users/jbishop/.rconfig.R')
}

source('/Users/jbishop/git/electricity_logging/plotting/barplot.R')

query <- "SELECT label, kwh, previous_yeartodate_kwh AS kwh_avg, complete FROM electricity_plotting.electricity_yearly;"
res <- dbGetQuery(con, query)

fname <- '/tmp/yearly.png'
cname <- '/tmp/yearly.csv'
title <- "Electricity Usage By Year"
label.x <- "Year"
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
#barplot(res$kwh, names.arg=res$month, col=res$col)
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)

write.table(res, file=cname, row.names=F, col.names=T, quote=F, sep=',')
