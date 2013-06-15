bp <- function(x=res$kwh, names, pts){
    col <- rep('x', length(res$kwh))
    pcol <- rep('x', length(res$kwh))
    col[res$kwh > res$kwh_avg] <- 'rosybrown' #557
    col[res$kwh <= res$kwh_avg] <- 'lightgoldenrod' #410
    col[col == 'x'] <- 'lightgoldenrod'
    pcol[res$kwh > res$kwh_avg] <- 'firebrick'
    pcol[res$kwh <= res$kwh_avg] <- 'darkgoldenrod'
    pcol[pcol == 'x'] <- 'darkgoldenrod'
    b <- barplot(x, names.arg=names, col=col)
    points(b, pts, pch=19, col=pcol)
}
