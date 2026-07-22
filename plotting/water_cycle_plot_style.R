cycle_bg <- '#f8fafc'
cycle_panel <- '#ffffff'
cycle_axis <- '#475569'
cycle_grid <- '#e2e8f0'
cycle_text <- '#0f172a'
cycle_blue <- '#2563eb'
cycle_blue_light <- '#93c5fd'
cycle_orange <- '#f59e0b'
cycle_red <- '#dc2626'
cycle_gold <- '#b45309'
cycle_grey <- '#64748b'

cycle_plot_init <- function(fname, width=1024, height=400) {
    png(filename=fname, width=width, height=height, units='px', pointsize=12, bg=cycle_bg)
    par(
        bg=cycle_bg,
        mar=c(4, 4.5, 3, 1.5),
        mgp=c(2.4, 0.7, 0),
        tcl=-0.25,
        col.axis=cycle_axis,
        col.lab=cycle_axis,
        col.main=cycle_text,
        fg=cycle_axis,
        bty='n',
        las=1
    )
}

cycle_draw_panel <- function(xlim, ylim, xlab, ylab, main, xaxt='n', yaxt='n') {
    plot(xlim, ylim, type='n', xlim=xlim, ylim=ylim, xlab=xlab, ylab=ylab, main=main, xaxt=xaxt, yaxt=yaxt)
    rect(xlim[1], ylim[1], xlim[2], ylim[2], col=cycle_panel, border=NA)
}

cycle_axis_time <- function(at, labels=substr(at, 12, 16)) {
    axis(side=1, at=at, labels=labels, col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
}

cycle_axis_y <- function(at, labels=at) {
    axis(side=2, at=at, labels=labels, col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
}

cycle_grid_lines <- function(h=NULL, v=NULL) {
    if (!is.null(h)) {
        abline(h=h, col=cycle_grid, lty=1)
    }
    if (!is.null(v)) {
        abline(v=v, col=cycle_grid, lty=1)
    }
}

cycle_legend <- function(...) {
    legend(..., bty='n', text.col=cycle_axis)
}
