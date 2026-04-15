# Helper file: plot_helpers.R
# Purpose: Starter location for plotting helpers used across the workflow
# Expected inputs: Tidy result objects and plotting parameters
# Outputs: Consistent ggplot-based figures for QC and result summaries

theme_portfolio_qc <- function() {
  ggplot2::theme_minimal(base_size = 11) +
    ggplot2::theme(
      plot.title = ggplot2::element_text(face = "bold"),
      panel.grid.minor = ggplot2::element_blank()
    )
}

save_plot_if_provided <- function(plot_object, path, width = 7, height = 5, dpi = 300) {
  if (is.null(plot_object)) {
    return(invisible(NULL))
  }

  ggplot2::ggsave(
    filename = path,
    plot = plot_object,
    width = width,
    height = height,
    dpi = dpi
  )

  invisible(path)
}

# TODO: Add project-specific plotting helpers once the QC and results figure set is defined.
