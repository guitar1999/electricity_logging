library(RPostgreSQL)
con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")

query <- "SELECT dow, hour, AVG(kwh) AS kwh FROM (SELECT date_part('dow', measurement_time) AS dow, date_part('hour', measurement_time) AS hour, SUM((watts_ch1 + watts_ch2) * tdiff / 60 / 60 / 1000.) AS kwh FROM electricity_measurements GROUP BY dow, hour, date_part('doy', measurement_time)) AS x GROUP BY dow, hour;"
res <- dbGetQuery(con, query)

fname <- '/var/www/electricity/average_hourly_by_dow.png'

png(filename=fname, width=1024, height=400, units='px', pointsize=12, bg='white')
dev.off()

system(paste("scp", fname, "web309.webfaction.com:/home/jessebishop/webapps/htdocs/home/frompi/electricity/", sep=' '))

