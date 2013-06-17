bp <- function(res){
    col <- rep('x', length(res$kwh))
    pcol <- rep('x', length(res$kwh))
    pdcol <- rep('x', length(res$kwh))
    col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
    col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410
    col[col == 'x'] <- 'lightgoldenrod'
    pcol[res$kwh > res$kwh_avg] <- 'firebrick'
    pcol[res$kwh <= res$kwh_avg] <- 'darkgoldenrod'
    pcol[pcol == 'x'] <- 'darkgoldenrod'
    res[res$complete == 'no',1] <- paste(res[res$complete == 'no',1], '*', sep='')
    names <- res[,1]
    b <- barplot(res$kwh, names.arg=names, col=col)
    if ("kwh_avg" %in% colnames(res)){
        res$kwh_avg_plot <- res$kwh_avg
        res$kwh_avg_plot[res$kwh_avg > max(res$kwh)] <- max(res$kwh)
        res$kwh_avg_pch <- 19
        res$kwh_avg_pch[res$kwh_avg > max(res$kwh)] <- 8
        points(b, res$kwh_avg_plot, pch=res$pch, col=pcol)
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
