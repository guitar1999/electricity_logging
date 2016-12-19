if (! 'package:plotrix' %in% search()) {
    require(plotrix)
}
bp <- function(res, title, label.x, label.y, sunrise=NULL, sunset=NULL){
    # Define the barplotting function, since it may need to be called more than once depending on the graph.
    bpf <- function(kwh, label, col, main, xlab, ylab, xpd, las, add){
        barplot(kwh, names.arg=label, col=col, main=main, xlab=xlab, ylab=ylab, xpd=xpd, las=las, add=add)
    }
    # Generate a vector of bar colors
    col <- rep('x', length(res$kwh))
    col[res$kwh > res$kwh_avg] <- rgb(188/255, 143/255, 143/255, 175/255) #rosybrown 557
    col[res$kwh <= res$kwh_avg] <- rgb(238/255, 221/255, 130/255, 200/255) #lightgoldenrod 410
    col[col == 'x'] <- 'lightgoldenrod'
    # Generate a vector of point colors
    pcol <- rep('x', length(res$kwh))
    pcol[res$kwh > res$kwh_avg] <- 'firebrick'
    pcol[res$kwh <= res$kwh_avg] <- 'darkgoldenrod'
    pcol[pcol == 'x'] <- 'darkgoldenrod'
    # Generate a vector of alternate point colors
    pdcol <- rep('x', length(res$kwh))
    # Add qualifier to label where the aggregation period is not complete
    res$label[res$complete == 'no'] <- paste(res$label[res$complete == 'no'], '*', sep='')
    # Generate the barplot and store it as an object to have the bar midpoint locations for later use
    b <- bpf(res$kwh, res$label, col, title, label.x, label.y, FALSE, ifelse("jday" %in% colnames(res),2,1), FALSE)
    # Add a gradient for nighttime to the barplot.
    if (! is.null(sunrise)) {
        # Get the bar midpoint distance
        bd <- b[2] - b[1]
        # Split the hours, minutes, and seconds for the rise and set
        riseparts <- unlist(strsplit(sunrise, ':'))
        setparts <- unlist(strsplit(sunset, ':'))
        # Calculate the position on the barplot for rise and set (Get the value of the bar midpoint by finding the
        # position of the hour in the label column (removing the * if the hour is incomplete) and add the fraction of the 
        # bar midpoint distance that represents the minutes of the hour (bar midpoint is half past the hour)).
        risepos <- b[which(gsub('*', '', res$label, fixed=TRUE) == as.numeric(riseparts[1]))] + ((as.numeric(riseparts[2]) - 30) / 60 * bd)
        setpos <- b[which(gsub('*', '', res$label, fixed=TRUE) == as.numeric(setparts[1]))] + ((as.numeric(setparts[2]) - 30) / 60 * bd)
        # Draw the gradient. First case is if nighttime is not split. The second case is if it is.
        if (risepos > setpos) {
            gradient.rect(setpos, 0, setpos + (risepos - setpos) / 2, max(res$kwh), col=smoothColors('white', 255, 'grey22'), gradient='x', border=NA)
            gradient.rect(setpos + (risepos - setpos) / 2, 0, risepos, max(res$kwh), col=smoothColors('grey22', 255, 'white'), gradient='x', border=NA)
        } else {
            # Calculate start and end of gradient on either side of plot
            gstart <- -1 * (b[length(b)] + 0.7 - setpos)
            gsmid <- gstart + (risepos - gstart) / 2
            gend <- b[length(b)] + 0.7 + risepos
            gemid <- gend - (gend - setpos) / 2
            gradient.rect(gstart, 0, gsmid, max(res$kwh), col=smoothColors('white', 255, 'grey22'), gradient='x', border=NA)
            gradient.rect(gsmid, 0, risepos, max(res$kwh), col=smoothColors('grey22', 255, 'white'), gradient='x', border=NA)
            gradient.rect(setpos, 0, gemid, max(res$kwh), col=smoothColors('white', 255, 'grey22'), gradient='x', border=NA)
            gradient.rect(gemid, 0, gend, max(res$kwh), col=smoothColors('grey22', 255, 'white'), gradient='x', border=NA)
        }
    } # End gradient
    # Generate some horizontal lines
    linelookup <- data.frame(rbind(c(15, 5), c(5, 2), c(1, 0.1)))
    pwr <- nchar(as.character(as.integer(max(res$kwh)))) - 1
    yseq <- seq(0,ceiling(max(res$kwh)/10^pwr)*10^pwr,ifelse(pwr > 1, ifelse(max(res$kwh) > 400, 10^pwr, 10^pwr / 2), ifelse(max(res$kwh) > 77, 20, ifelse(max(res$kwh) > 38, 10, ifelse(max(res$kwh) > 15.5, 5, ifelse(max(res$kwh) > 7.6, 2, ifelse(max(res$kwh) > 3.75, 1, ifelse(max(res$kwh) > 1.5, 0.5, ifelse(max(res$kwh) > 0.75, 0.2, ifelse(max(res$kwh) > 0.35, 0.1, ifelse(max(res$kwh) > 0.15, 0.05, 0.02)))))))))))
    abline(h=yseq, col='darkgray')
    # Draw the barplot again over the gradient
    bpf(res$kwh, res$label, col, title, label.x, label.y, FALSE, ifelse("jday" %in% colnames(res),2,1), TRUE)
    # If this plot has an average value, draw the points
    if ("kwh_avg" %in% colnames(res)){
        res$kwh_avg_plot <- res$kwh_avg
        res$kwh_avg_plot[res$kwh_avg > max(res$kwh)] <- max(res$kwh) - max(res$kwh) / 100
        res$kwh_avg_pch <- 19
        res$kwh_avg_pch[res$kwh_avg > max(res$kwh)] <- 8
        if ('By' %in% strsplit(title, ' ')[[1]]){
            res$kwh_avg_pch <- 18
            legend('bottomleft','Previous Year-to-Date', pch=18, col=pcol)
        }
        points(b, res$kwh_avg_plot, pch=res$kwh_avg_pch, col=pcol)
    }
    # If this polot has an average by day of week value, draw the points
    if ("kwh_avg_dow" %in% colnames(res)){
        pdcol[res$kwh > res$kwh_avg_dow] <- 'firebrick'
        pdcol[res$kwh <= res$kwh_avg_dow] <- 'darkgoldenrod'
        pdcol[pcol == 'x'] <- 'darkgoldenrod'
        res$kwh_avg_dow_plot <- res$kwh_avg_dow
        res$kwh_avg_dow_plot[res$kwh_avg_dow > max(res$kwh)] <- max(res$kwh)
        res$kwh_avg_dow_pch <- 19
        res$kwh_avg_dow_pch[res$kwh_avg_dow > max(res$kwh)] <- 8
        points(b, res$kwh_avg_dow, col=pdcol, pch=res$kwh_avg_dow_pch)
    }
    if ("btu_avg" %in% colnames(res)){
	print("hi")
        pdcol[res$btu > res$btu_avg] <- 'darkorange'
        pdcol[res$btu <= res$btu_avg] <- 'darkorange'
        pdcol[pcol == 'x'] <- 'darkorange'
        res$btu_avg_plot <- res$btu_avg
        res$btu_avg_plot[res$btu_avg > max(res$btu)] <- max(res$btu)
        res$btu_avg_pch <- 19
        res$btu_avg_pch[res$btu_avg > max(res$btu)] <- 8
        points(b, res$btu_avg, col=pdcol, pch=res$btu_avg_pch)
    }
}
