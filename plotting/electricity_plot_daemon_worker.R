require(plotrix)
require(RPostgreSQL)

# Make a connection to the database
source('/home/jessebishop/.rconfig.R')

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
while(TRUE){
    print(paste("Ticker is ", ticker, sep=""))
    # Set the runtime for this loop to zero and add the holdover if there is any
    runtime <- as.difftime(0, units='secs') + holdover
    print(paste("    Starting runtime is ",runtime, sep=""))

    # Run the first plot (every loop) and add the plotting time to the loop runtime
    plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_last_hour.R')
    runtime <- runtime + plottime
    print("    line")
    # plottime <- genplot('/usr/local/gas_logging/plotting/generate_plot_oil_last_hour.R')
    # runtime <- runtime + plottime
    # print("    oil line")

    # Run the hourlies every 2nd loop and add the plotting time to the loop runtime
    if (ticker %% 2 == 0 && ticker != 0){
        # plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_hourly.R')
        # runtime <- runtime + plottime
        # print("    hourly")
        # plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_hourly_dow.R')
        # runtime <- runtime + plottime
        # print("    hourlydow")
        plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_hourly_season.R')
        runtime <- runtime + plottime
        print("    hourlyseason")
        # plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_hourly_dow_season.R')
        # runtime <- runtime + plottime
        # print("    hourlydowseason")
        plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_hourly_season_cmp.R')
        runtime <- runtime + plottime
        print("    hourlyseasoncmp")
        plottime <- genplot('/usr/local/gas_logging/plotting/generate_plot_oil_hourly.R')
        runtime <- runtime + plottime
        print("    oil hourly")
        plottime <- genplot('/usr/local/gas_logging/plotting/generate_plot_oil_hourly_dow_season.R')
        runtime <- runtime + plottime
        print("    oil hourlydowseason")
    }

    # Run the month_to_month at 7 past the hour and add the plotting timest to the loop runtime
    if (ticker == 7){
        # plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_month_to_month.R')
        # runtime <- runtime + plottime
        # print("    month to month")
    }

    # Run the dow every 2nd loop and add the plotting times to the loop runtime
    if (ticker %% 2 == 0 && ticker != 0){
        plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_dow.R')
        runtime <- runtime + plottime
        print("    dow")
        plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_dow_season.R')
        runtime <- runtime + plottime
        print("    dowseason")
        plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_daily.R')
        runtime <- runtime + plottime
        print("    daily")
        plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_last_24_hours.R')
        runtime <- runtime + plottime
        print("    24 hours")
        plottime <- genplot('/usr/local/gas_logging/plotting/generate_plot_oil_dow.R')
        runtime <- runtime + plottime
        print("    oil dow")
        plottime <- genplot('/usr/local/gas_logging/plotting/generate_plot_oil_dow_season.R')
        runtime <- runtime + plottime
        print("    oil dowseason")
        plottime <- genplot('/usr/local/gas_logging/plotting/generate_plot_oil_daily.R')
        runtime <- runtime + plottime
        print("    oil daily")
    }

    # Run the daily every 2nd and add the plotting times to the loop runtime
    if (ticker %% 2 == 0 && ticker != 0){
        plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_monthly.R')
        runtime <- runtime + plottime
        print("    monthly")
        plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_yearly.R')
        runtime <- runtime + plottime
        print("    yearly")
        plottime <- genplot('/usr/local/gas_logging/plotting/generate_plot_oil_monthly.R')
        runtime <- runtime + plottime#        print("    oil monthly")
        print("    oil monthly")
        plottime <- genplot('/usr/local/gas_logging/plotting/generate_plot_oil_yearly.R')
        runtime <- runtime + plottime
        print("    oil yearly")
    }

    # Run the monthly and daily 1year every 30th loop and add the plotting times to the loop runtime
    if (ticker %% 2 == 0 && ticker != 0){
        plottime <- genplot('/usr/local/electricity_logging/plotting/generate_plot_daily_1year.R')
        runtime <- runtime + plottime
        print("    daily 1year")
        plottime <- genplot('/usr/local/gas_logging/plotting/generate_plot_oil_daily_1year.R')
        runtime <- runtime + plottime
        print("    oil daily 1year")
    }


    # Calculate the sleep time or holdover time for the loop
    looptime <- as.difftime(60, units='secs')
    print(paste("    Ending runtime is ", runtime, sep=''))
    if (runtime <= looptime){
        sleeptime <- looptime - runtime
        holdover <- as.difftime(0, units='secs')
        print(paste("    Sleep time is ", sleeptime, sep=""))
        Sys.sleep(sleeptime)
    } else {
        holdover <- runtime - looptime
        print(paste("    Holdover is ", holdover, sep=""))
        if (holdover > 600) {
            q(save='no', status=1)
        }
    }


    # Increment the loop ticker
    if (ticker < 59){
        ticker <- ticker + 1
    } else {
        endtime <- Sys.time()
        print(paste("This cycle took ", endtime - starttime, sep=""))
        ticker <- 0
        end.minute <- as.numeric(format(endtime, "%M"))
        end.second <- as.numeric(format(endtime, "%S"))
        if (end.minute < 58){
            holdover <- holdover + (end.minute * 60 + end.second)
            print(paste("Holdover at cycle end is ", holdover, sep=""))
        } else {
            cyclesleeptime <- (60 - end.minute) * 60 - end.second
            print(paste("Sleep time at cycle end is ", cyclesleeptime, sep=""))
            Sys.sleep(cyclesleeptime)
        }
        starttime <- Sys.time()
    }
}

# We should never get here!
print("how'd we get here?")
