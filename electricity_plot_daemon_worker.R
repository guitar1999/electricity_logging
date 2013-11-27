require(plotrix)
require(RPostgreSQL)

# Make a connection to the database
con <- dbConnect(drv="PostgreSQL", host="127.0.0.1", user="jessebishop", dbname="jessebishop")

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
    plottime <- genplot('/home/jessebishop/scripts/electricity_logging/generate_plot_last_hour.R')
    runtime <- runtime + plottime
    print("    line")

    # Run the hourlies every 5th loop and add the plotting time to the loop runtime
    if (ticker %% 5 == 0){
        plottime <- genplot('/home/jessebishop/scripts/electricity_logging/generate_plot_hourly.R')
        runtime <- runtime + plottime
        print("    hourly")
        plottime <- genplot('/home/jessebishop/scripts/electricity_logging/generate_plot_hourly_dow.R')
        runtime <- runtime + plottime
        print("    hourlydow")
        plottime <- genplot('/home/jessebishop/scripts/electricity_logging/generate_plot_last_24_hours.R')
        runtime <- runtime + plottime
        print("    24 hours")
    }

    # Run the dow every 11th loop and add the plotting times to the loop runtime
    if (ticker %% 11 == 0){
        plottime <- genplot('/home/jessebishop/scripts/electricity_logging/generate_plot_dow.R')
        runtime <- runtime + plottime
        print("    dow")
    }

    # Run the daily every 13th loop and add the plotting times to the loop runtime
    if (ticker %% 13 == 0){
        plottime <- genplot('/home/jessebishop/scripts/electricity_logging/generate_plot_daily.R')
        runtime <- runtime + plottime
        print("    daily")
    }

    # Run the monthly and daily 1year every 16th loop and add the plotting times to the loop runtime
    if (ticker == 1 || ticker %% 16 == 0){
        plottime <- genplot('/home/jessebishop/scripts/electricity_logging/generate_plot_monthly.R')
        runtime <- runtime + plottime
        print("    monthly")
        plottime <- genplot('/home/jessebishop/scripts/electricity_logging/generate_plot_daily_1year.R')
        runtime <- runtime + plottime
        print("    daily 1year")
    }

    # Run the yearly on the 6th and 36th loops
    if (ticker == 6 || ticker == 36){
        plottime <- genplot('/home/jessebishop/scripts/electricity_logging/generate_plot_yearly.R')
        runtime <- runtime + plottime
        print("    yearly")
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
    }

    
    # Increment the loop ticker
    if (ticker < 59){
        ticker <- ticker + 1
    } else {
        print(paste("This cycle took ", Sys.time() - starttime, sep=""))
        ticker <- 0
        starttime <- Sys.time()
    }
}

# We should never get here!
print("how'd we get here?")
