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
        #res$kwh_avg_plot[res$kwh_avg
        points(b, res$kwh_avg, pch=19, col=pcol)
    }
    if ("kwh_avg_dow" %in% colnames(res)){
        pdcol[res$kwh > res$kwh_avg_dow] <- 'firebrick'
        pdcol[res$kwh <= res$kwh_avg_dow] <- 'darkgoldenrod'
        pdcol[pcol == 'x'] <- 'darkgoldenrod'
        points(b, res$kwh_avg_dow, col=pdcol, pch=18)
    }
}
