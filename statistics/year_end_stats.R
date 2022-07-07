library(RPostgreSQL)
source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))
query <- "SELECT watts_ch1 + watts_ch2 AS watts, tdiff, measurement_time from electricity_measurements where measurement_time >= '2013-03-21 16:00:54.706155-04' and measurement_time < '2014-03-21 16:00:54.706155-04' order by measurement_time;"
all <- dbGetQuery(con, query)
query2 <- "SELECT min(watts_ch1 + watts_ch2) AS min_watts, avg(watts_ch1 + watts_ch2) AS mean_watts, max(watts_ch1 + watts_ch2) AS max_watts, measurement_time::date AS meas_date FROM electricity_measurements where measurement_time >= '2013-03-21 16:00:54.706155-04' and measurement_time < '2014-03-21 16:00:54.706155-04' GROUP BY measurement_time::date ORDER BY measurement_time::date;"
daily <- dbGetQuery(con, query2)
