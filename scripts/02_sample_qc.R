# Script: 02_sample_qc.R
# Purpose: Define a cautious, reproducible template for sample-level QC and exploratory checks
# Expected inputs: Imported methylation object and sample metadata in data/processed or data/metadata
# Outputs: QC plan objects, empty tracking files, and a structured checklist for future QC outputs

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))
source(file.path("functions", "plot_helpers.R"))

qc_files <- list(
  summary_table = file.path(paths$results_qc, "sample_qc_summary.csv"),
  exclusion_log = file.path(paths$results_qc, "sample_exclusion_log.csv"),
  qc_notes = file.path(paths$results_qc, "qc_notes.txt")
)

qc_checklist <- tibble::tibble(
  qc_step = c(
    "Confirm sample counts and group labels",
    "Inspect metadata completeness",
    "Review available technical variables",
    "Assess missingness and obvious outliers",
    "Review control metrics if raw array data are available",
    "Check reported sex against methylation-derived sex if feasible",
    "Document exclusion decisions with reasons"
  ),
  required_before_modelling = c(TRUE, TRUE, TRUE, TRUE, FALSE, FALSE, TRUE),
  status = "pending",
  notes = ""
)

sample_qc_summary <- tibble::tibble(
  metric = c(
    "dataset_accession",
    "samples_total",
    "samples_cases",
    "samples_controls",
    "metadata_rows",
    "metadata_missing_group_labels",
    "raw_array_metrics_available",
    "sex_check_possible"
  ),
  value = NA_character_
)

sample_exclusion_log <- tibble::tibble(
  sample_id = character(),
  exclusion_stage = character(),
  exclusion_reason = character(),
  decision_recorded_by = character(),
  decision_date = character(),
  notes = character()
)

write_csv_if_missing(sample_qc_summary, qc_files$summary_table)
write_csv_if_missing(sample_exclusion_log, qc_files$exclusion_log)

if (!file.exists(qc_files$qc_notes)) {
  writeLines(
    c(
      "Sample QC notes",
      "",
      "Use this file to record dataset-specific QC decisions, assumptions, and unresolved issues.",
      "Do not remove samples without documenting the reason in sample_exclusion_log.csv."
    ),
    con = qc_files$qc_notes
  )
}

print(qc_checklist)

# TODO: Load the imported methylation object once the dataset and storage format are finalized.
# TODO: Load and clean sample metadata from data/metadata.
# TODO: Populate sample_qc_summary with real counts and data availability flags.
# TODO: Add dataset-specific QC thresholds only after confirming platform and input format.
# TODO: Generate exploratory QC figures and save them under results/qc.

# Starter note:
# Keep every QC exclusion explicit, minimal, and easy to justify in the portfolio narrative.
