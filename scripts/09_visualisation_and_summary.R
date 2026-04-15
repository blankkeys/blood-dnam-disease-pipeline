# Script: 09_visualisation_and_summary.R
# Purpose: Define a minimal, portfolio-friendly set of figures and summary outputs
# Expected inputs: QC outputs, differential methylation tables, and annotation or enrichment summaries
# Outputs: Figure planning tables and summary templates in results/figures and reports

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))
source(file.path("functions", "plot_helpers.R"))

summary_files <- list(
  figure_plan = file.path(paths$results_figures, "figure_plan.csv"),
  summary_table_plan = file.path(paths$reports, "summary_table_plan.csv"),
  reporting_notes = file.path(paths$reports, "reporting_notes.txt")
)

figure_plan <- tibble::tibble(
  figure_name = c(
    "sample_qc_overview",
    "covariate_balance_summary",
    "volcano_plot",
    "top_hit_annotation_summary",
    "enrichment_summary_plot"
  ),
  required_for_portfolio = c(TRUE, TRUE, TRUE, TRUE, FALSE),
  input_dependency = c(
    "sample QC outputs",
    "cleaned metadata and covariate review",
    "differential methylation results",
    "annotation results",
    "enrichment results"
  ),
  status = "pending",
  notes = ""
)

summary_table_plan <- tibble::tibble(
  table_name = c(
    "dataset_overview",
    "sample_exclusion_summary",
    "top_differential_methylation_hits",
    "annotation_summary",
    "enrichment_summary"
  ),
  intended_contents = c(
    "sample counts, platform, and key metadata availability",
    "number of excluded samples and reasons",
    "top associations with core statistics and cautious labels",
    "selected annotated probes with genomic context",
    "exploratory pathway summary if performed"
  )
)

write_csv_if_missing(figure_plan, summary_files$figure_plan)
write_csv_if_missing(summary_table_plan, summary_files$summary_table_plan)

if (!file.exists(summary_files$reporting_notes)) {
  writeLines(
    c(
      "Reporting notes",
      "",
      "Use this file to document which figures and tables are included in the portfolio summary.",
      "Keep visuals clear, modest, and easy to explain without overstating certainty."
    ),
    con = summary_files$reporting_notes
  )
}

print(figure_plan)

# TODO: Finalize a minimal figure set once real QC and modeling outputs exist.
# TODO: Use beta values for intuitive plotting where appropriate while keeping modeling decisions documented separately.
# TODO: Keep captions and table labels descriptive rather than causal.
# TODO: Save publication-style figures only after the analysis outputs are stable.
