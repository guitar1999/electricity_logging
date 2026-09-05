source(paste(githome, '/electricity_logging/plotting/water_cycle_plot_style.R', sep=''))

cycle_count_bar_plot <- function(res, fname, title, xlab, ylab, las=1) {
    width <- 1024
    height <- 400
    png(filename=fname, width=width, height=height, units='px', pointsize=12, bg=cycle_bg)
    par(
        bg=cycle_bg,
        mar=c(4.5, 4.5, 3.5, 1.5),
        mgp=c(2.4, 0.7, 0),
        tcl=-0.25,
        col.axis=cycle_axis,
        col.lab=cycle_axis,
        col.main=cycle_text,
        fg=cycle_axis,
        bty='n',
        las=las
    )

    ymax <- ifelse(nrow(res) > 0, max(1, res$cycles, na.rm=TRUE), 1)
    yseq <- pretty(c(0, ymax))
    if (max(yseq) < ymax) {
        yseq <- pretty(c(0, ceiling(ymax)))
    }

    cycle_draw_panel(c(0.25, max(1, nrow(res)) + 0.75), range(yseq), xlab, ylab, title)
    cycle_grid_lines(h=yseq)
    cycle_axis_y(yseq)

    if (nrow(res) > 0) {
        bar_col <- ifelse(res$complete == 'no', adjustcolor(cycle_blue_light, alpha.f=0.75), cycle_blue)
        rect(
            seq_len(nrow(res)) - 0.36,
            0,
            seq_len(nrow(res)) + 0.36,
            res$cycles,
            col=bar_col,
            border=NA
        )
        axis(side=1, at=seq_len(nrow(res)), labels=res$label, col=NA, col.ticks=cycle_axis, col.axis=cycle_axis)
        if (any(res$complete == 'no')) {
            cycle_legend('topleft', legend=c('Complete period', 'Current partial period'), fill=c(cycle_blue, adjustcolor(cycle_blue_light, alpha.f=0.75)), border=NA, inset=0.01)
        }
    } else {
        text(0.5, mean(yseq), 'No cycles found', col=cycle_axis)
    }

    dev.off()
}
