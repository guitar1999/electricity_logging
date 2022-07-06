if (! 'package:RPostgreSQL' %in% search()) {
    library(RPostgreSQL)
    source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
}

source(paste(githome, '/electricity_logging/plotting/barplot.R', sep=''))

query <- "SELECT label, kwh, previous_year AS kwh_avg, complete FROM electricity_plotting.electricity_daily WHERE row_number < 31;"
res <- dbGetQuery(con, query)

res$jday <- res$label # Fake it until I fix barplot function to take las as an argument

fname <- '/tmp/daily.png'
title <- "Electricity Used in the Last Month"
label.x <- ""
label.y <- "kwh"

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
bp(res, title, label.x, label.y)
dev.off()

system(paste("scp", fname, paste(paste(webuser, webhost, sep="@"), paste(webpath, 'electricity2', sep="/"), sep=":"), sep=' '),ignore.stdout=TRUE,ignore.stderr=TRUE)
