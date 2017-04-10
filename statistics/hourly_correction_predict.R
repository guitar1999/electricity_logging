library('randomForest')
load('/usr/local/electricity_logging/statistics/hourly_correction_model.RData')

# Get args
args <- commandArgs(trailingOnly=TRUE)
sum_date <- args[1]
hour <- args[2]
kwh_ch1 <- args[3]
kwh_ch2 <- args[4]

pdata <- rbind(sum_date, hour, kwh_ch1, kwh_ch2)
pred <- predict(rf.model, pdata)

print(pred)
