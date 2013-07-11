require(plotrix)
bp <- function(res, title, label.x, label.y, sunrise=NULL, sunset=NULL){
    # Generate a vector of bar colors
    col <- rep('x', length(res$kwh))
    col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
    col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410
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
    b <- barplot(res$kwh, names.arg=res$label, col=col, main=title, xlab=label.x, ylab=label.y, xpd=FALSE, las=ifelse("jday" %in% colnames(res),2,1))
    # Add a line for sunrise and/or sunset to the barplot
    if (! is.null(sunrise)) {
        # Get the bar midpoint distance
        bd <- b[2] - b[1]
        riseparts <- unlist(strsplit(sunrise, ':'))
        setparts <- unlist(strsplit(sunset, ':'))
        risepos <- b[which(res$label == as.numeric(riseparts[1]))] + ((as.numeric(riseparts[2]) - 30) / 60 * bd)
        setpos <- b[which(res$label == as.numeric(setparts[1]))] + ((as.numeric(setparts[2]) - 30) / 60 * bd)
        if (risepos > setpos) {
            gradient.rect(setpos, 0, setpos + (risepos - setpos) / 2, max(res$kwh), col=smoothColors('white', 255, 'black'), gradient='x', border=NA)
            gradient.rect(setpos + (risepos - setpos) / 2, 0, risepos, max(res$kwh), col=smoothColors('black', 255, 'white'), gradient='x', border=NA)
        } else {

        }
        barplot(res$kwh, names.arg=res$label, col=col, main=title, xlab=label.x, ylab=label.y, xpd=FALSE, las=ifelse("jday" %in% colnames(res),2,1), add=TRUE)
        #abline(v=risepos, lwd=2, col='orangered2', lty=2)
        #abline(v=setpos, lwd=2, col='orangered2', lty=2)
    }
    if ("kwh_avg" %in% colnames(res)){
        res$kwh_avg_plot <- res$kwh_avg
        res$kwh_avg_plot[res$kwh_avg > max(res$kwh)] <- max(res$kwh) - max(res$kwh) / 100
        res$kwh_avg_pch <- 19
        res$kwh_avg_pch[res$kwh_avg > max(res$kwh)] <- 8
        points(b, res$kwh_avg_plot, pch=res$kwh_avg_pch, col=pcol)
    }
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
}
