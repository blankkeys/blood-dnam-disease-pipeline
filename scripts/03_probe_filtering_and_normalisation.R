# Script: 03_probe_filtering_and_normalisation.R
# Purpose: Define a cautious template for probe filtering and normalization decisions
# Expected inputs: QC-passed methylation object and platform information
# Outputs: Filtering plan objects, starter tracking files, and documented normalization choices

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

filtering_files <- list(
  filtering_decisions = file.path(paths$results_qc, "probe_filtering_decisions.csv"),
  filtering_notes = file.path(paths$results_qc, "probe_filtering_notes.txt"),
  normalisation_plan = file.path(paths$data_metadata, "normalisation_plan.csv")
)

probe_filtering_plan <- tibble::tibble(
  filtering_step = c(
    "Confirm array platform and annotation source",
    "Review detection p-value availability",
    "Assess bead count or intensity-based quality metrics if available",
    "Decide how to handle probes affected by SNPs or poor mapping",
    "Decide whether sex chromosome probes will be retained",
    "Record preprocessing assumptions inherited from the source dataset"
  ),
  applies_if_raw_data_available = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
  status = "pending",
  notes = ""
)

normalisation_plan <- tibble::tibble(
  decision_area = c(
    "input_data_level",
    "platform",
    "candidate_normalisation_method",
    "reason_for_method_choice",
    "sensitivity_analysis_needed",
    "processed_object_output"
  ),
  value = c(
    NA_character_,
    NA_character_,
    NA_character_,
    NA_character_,
    "yes",
    file.path("data", "processed", "methylation_processed.rds")
  )
)

write_csv_if_missing(probe_filtering_plan, filtering_files$filtering_decisions)
write_csv_if_missing(normalisation_plan, filtering_files$normalisation_plan)

if (!file.exists(filtering_files$filtering_notes)) {
  writeLines(
    c(
      "Probe filtering and normalisation notes",
      "",
      "Use this file to document platform-specific filtering choices and any inherited preprocessing from the source dataset.",
      "Avoid defaulting to aggressive filtering rules before the array platform and input type are confirmed."
    ),
    con = filtering_files$filtering_notes
  )
}

print(probe_filtering_plan)

# TODO: Load the QC-passed methylation object after the dataset import pathway is finalized.
# TODO: Confirm whether the project will start from raw IDAT files or a processed matrix.
# TODO: Add platform-specific filtering criteria only after confirming 450K vs EPIC and available QC metrics.
# TODO: Record the chosen normalization approach and why it is appropriate for the selected input format.
# TODO: Save the processed methylation object under data/processed once real preprocessing begins.

# Keep filtering and normalization choices modest, documented, and easy to justify.
