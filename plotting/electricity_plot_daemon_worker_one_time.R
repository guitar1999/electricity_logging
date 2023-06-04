require(plotrix)
require(RPostgreSQL)

# Make a connection to the database
source(paste(Sys.getenv('HOME'), '/.rconfig.R', sep=''))

# A function to run the plotting script and return the time
genplot <- function(scr){
    t0 <- Sys.time()
    source(scr)
    ttotal <- Sys.time() - t0
    return(ttotal)
}

######################
# The plot scheduler #
######################

# Set a ticker to the current minute. We will count 60 iterations of the script
# and if everything works out well, that will be equal to 1 hour.
ticker <- as.integer(strftime(Sys.time(), format='%M'))
starttime <- Sys.time()
print(paste("Start time is ", starttime, sep=""))
# Set an empty holdover time
holdover <- as.difftime(0, units='secs')

# Loop infinitely!

print(paste("Ticker is ", ticker, sep=""))
# Set the runtime for this loop to zero and add the holdover if there is any
runtime <- as.difftime(0, units='secs') + holdover
print(paste("    Starting runtime is ",runtime, sep=""))

# Run the first plot (every loop) and add the plotting time to the loop runtime
plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_last_hour.R', sep=''))
runtime <- runtime + plottime
print("    line")

# Run the hourlies every 2nd loop and add the plotting time to the loop runtime
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_hourly_season.R', sep=''))
    runtime <- runtime + plottime
    print("    electricity hourly season")
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_hourly_season_cmp.R', sep=''))
    runtime <- runtime + plottime
    print("    electricity hourly season cmp")
    plottime <- genplot(paste(githome, '/gas_logging/plotting/generate_plot_oil_hourly_dow_season.R', sep=''))
    runtime <- runtime + plottime
    print("    oil hourly dow season")
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_water_hourly_dow_season.R', sep=''))
    runtime <- runtime + plottime
    print("    water hourly dow season")


# Run the month_to_month every 5 minutes and add the plotting timest to the loop runtime
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_month_to_month.R', sep=''))
    runtime <- runtime + plottime
    print("    electricity month to month")
    plottime <- genplot(paste(githome, '/gas_logging/plotting/generate_plot_oil_month_to_month.R', sep=''))
    runtime <- runtime + plottime
    print("    oil month to month")
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_water_month_to_month.R', sep=''))
    runtime <- runtime + plottime
    print("    water month to month")

# Run the dow every 2nd loop and add the plotting times to the loop runtime
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_dow_season.R', sep=''))
    runtime <- runtime + plottime
    print("    electricity dow season")
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_daily.R', sep=''))
    runtime <- runtime + plottime
    print("    electricity daily")
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_last_24_hours.R', sep=''))
    runtime <- runtime + plottime
    print("    electricity 24 hours")
    plottime <- genplot(paste(githome, '/gas_logging/plotting/generate_plot_oil_dow_season.R', sep=''))
    runtime <- runtime + plottime
    print("    oil dow season")
    plottime <- genplot(paste(githome, '/gas_logging/plotting/generate_plot_oil_daily.R', sep=''))
    runtime <- runtime + plottime
    print("    oil daily")
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_water_dow_season.R', sep=''))
    runtime <- runtime + plottime
    print("    water dow season")
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_water_daily.R', sep=''))
    runtime <- runtime + plottime
    print("    water daily")


# Run the daily every 2nd and add the plotting times to the loop runtime
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_monthly.R', sep=''))
    runtime <- runtime + plottime
    print("    electricity monthly")
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_yearly.R', sep=''))
    runtime <- runtime + plottime
    print("    electricity yearly")
    plottime <- genplot(paste(githome, '/gas_logging/plotting/generate_plot_oil_monthly.R', sep=''))
    runtime <- runtime + plottime#        print("    oil monthly")
    print("    oil monthly")
    plottime <- genplot(paste(githome, '/gas_logging/plotting/generate_plot_oil_yearly.R', sep=''))
    runtime <- runtime + plottime
    print("    oil yearly")
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_water_monthly.R', sep=''))
    runtime <- runtime + plottime
    print("    water monthly")
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_water_yearly.R', sep=''))
    runtime <- runtime + plottime
    print("    water yearly")


# Run the monthly and daily 1year every 30th loop and add the plotting times to the loop runtime
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_daily_1year.R', sep=''))
    runtime <- runtime + plottime
    print("    electricity daily 1year")
    plottime <- genplot(paste(githome, '/gas_logging/plotting/generate_plot_oil_daily_1year.R', sep=''))
    runtime <- runtime + plottime
    print("    oil daily 1year")
    plottime <- genplot(paste(githome, '/electricity_logging/plotting/generate_plot_water_daily_1year.R', sep=''))
    runtime <- runtime + plottime
    print("    water daily 1year")



