# Script: 03_probe_filtering_and_normalisation.R
# Purpose: Define a dataset-specific preprocessing plan for GSE42861 before any methylation preprocessing is run
# Expected inputs: Dataset selection notes, metadata cohort outputs, and a future decision on raw IDAT versus processed matrix entry
# Outputs: GSE42861-specific filtering and normalization planning files in data/metadata and results/qc

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

metadata_input <- file.path(paths$data_metadata, "GSE42861_analysis_cohort.csv")

filtering_files <- list(
  filtering_decisions = file.path(paths$results_qc, "GSE42861_probe_filtering_decisions.csv"),
  filtering_notes = file.path(paths$results_qc, "GSE42861_probe_filtering_notes.txt"),
  normalisation_plan = file.path(paths$data_metadata, "GSE42861_normalisation_plan.csv"),
  preprocessing_route = file.path(paths$data_metadata, "GSE42861_preprocessing_route.csv")
)

if (!file.exists(metadata_input)) {
  stop(
    "Metadata cohort file not found at ", metadata_input, ". ",
    "Run scripts/01_download_or_import_data.R first.",
    call. = FALSE
  )
}

cohort_metadata <- readr::read_csv(metadata_input, show_col_types = FALSE)

preprocessing_route <- tibble::tibble(
  decision_area = c(
    "dataset_accession",
    "platform",
    "raw_idat_available",
    "processed_matrix_available",
    "recommended_first_pass_entry",
    "why_this_entry_is_preferred",
    "raw_idat_role_later"
  ),
  value = c(
    "GSE42861",
    "Illumina HumanMethylation450 BeadChip",
    "yes",
    "yes",
    "processed_matrix",
    "keeps the first portfolio analysis smaller and easier to explain while metadata, cohort definition, and modelling strategy are still being finalized",
    "raw IDAT workflow can be added later as a stronger preprocessing extension once the initial processed-matrix pipeline is stable"
  )
)

probe_filtering_plan <- tibble::tibble(
  filtering_step = c(
    "Confirm that the imported object truly corresponds to 450K probe identifiers",
    "Check whether the processed matrix has already undergone source-side filtering",
    "Record whether low-quality probe filtering can be reproduced from available files",
    "Plan handling of SNP-affected or cross-reactive probes if probe-level annotation is available",
    "Decide how sex chromosome probes will be handled in a blood case-control setting",
    "Separate what is inherited from GEO processing versus what is done in this repository"
  ),
  applies_if_processed_matrix_start = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
  applies_if_raw_idat_start = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
  status = c("complete", "pending", "pending", "pending", "pending", "pending"),
  notes = c(
    "Dataset platform is already documented as GPL13534 / 450K",
    "Must be checked from GEO processed-matrix documentation before interpreting downstream results",
    "If starting from processed matrix, filtering claims should be conservative",
    "Useful for a later higher-fidelity preprocessing pass",
    "Should be documented explicitly rather than left implicit",
    "Important for portfolio transparency"
  )
)

normalisation_plan <- tibble::tibble(
  decision_area = c(
    "dataset_accession",
    "input_data_level",
    "platform",
    "candidate_normalisation_method",
    "reason_for_method_choice",
    "sensitivity_analysis_needed",
    "processed_object_output",
    "interpretation_limit"
  ),
  value = c(
    "GSE42861",
    "processed_matrix_first_pass",
    "Illumina HumanMethylation450 BeadChip",
    "inherit source-provided processed values for first-pass analysis; postpone array-level normalization decisions until raw IDAT workflow is in scope",
    "the current project priority is metadata, cohort definition, and modelling clarity rather than a full raw-array preprocessing build immediately",
    "yes",
    file.path("data", "processed", "GSE42861_methylation_processed.rds"),
    "if the first pass starts from processed values, preprocessing provenance must be described cautiously and not overstated as fully reproduced"
  )
)

readr::write_csv(preprocessing_route, filtering_files$preprocessing_route)
readr::write_csv(probe_filtering_plan, filtering_files$filtering_decisions)
readr::write_csv(normalisation_plan, filtering_files$normalisation_plan)

writeLines(
  c(
    "GSE42861 probe filtering and normalisation notes",
    "",
    "This script records the preprocessing route only and does not perform probe filtering or normalization yet.",
    "Because GSE42861 provides both raw IDATs and processed matrices, the project can support two entry paths.",
    "For the first-pass portfolio workflow, starting from the processed methylation matrix is the cleaner option because it keeps scope manageable while the metadata and model strategy are still being finalized.",
    "Any first-pass analysis that uses processed values should clearly state that preprocessing was inherited from the GEO-provided matrix rather than fully reproduced from raw arrays.",
    "A later extension can switch to the raw IDAT archive to support detection p-values, bead-count filtering, and explicit normalization choices."
  ),
  con = filtering_files$filtering_notes
)

print(preprocessing_route)
print(probe_filtering_plan)
print(normalisation_plan)

# Notes:
# - This step documents the preprocessing entry choice only.
# - No methylation matrix is loaded and no normalization is performed here.
