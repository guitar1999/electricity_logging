library(RPostgreSQL)
con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")

query <- "select watts_ch1 + watts_ch2, measurement_time from electricity_measurements where measurement_time > CURRENT_TIMESTAMP - ((date_part('minute', CURRENT_TIMESTAMP) + 60) * interval '1 minute');"
res <- dbGetQuery(con, query)

