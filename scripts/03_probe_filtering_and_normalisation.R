# Script: 03_probe_filtering_and_normalisation.R
# Purpose: Run a first preview-based matrix QC pass for GSE42861 and record preprocessing decisions before full methylation preprocessing
# Expected inputs: GSE42861 cohort metadata plus the processed-matrix preview object created by scripts/01_download_or_import_data.R
# Outputs: Dataset-specific preprocessing plans and preview QC summaries in data/metadata, data/processed, and results/qc

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

metadata_input <- file.path(paths$data_metadata, "GSE42861_analysis_cohort.csv")
preview_object_input <- file.path(paths$data_processed, "GSE42861_processed_matrix_preview.rds")

filtering_files <- list(
  filtering_decisions = file.path(paths$results_qc, "GSE42861_probe_filtering_decisions.csv"),
  filtering_notes = file.path(paths$results_qc, "GSE42861_probe_filtering_notes.txt"),
  normalisation_plan = file.path(paths$data_metadata, "GSE42861_normalisation_plan.csv"),
  preprocessing_route = file.path(paths$data_metadata, "GSE42861_preprocessing_route.csv"),
  preview_qc_summary = file.path(paths$results_qc, "GSE42861_processed_matrix_preview_qc_summary.csv"),
  preview_probe_missingness = file.path(paths$results_qc, "GSE42861_processed_matrix_preview_probe_missingness.csv"),
  preview_sample_missingness = file.path(paths$results_qc, "GSE42861_processed_matrix_preview_sample_missingness.csv"),
  preview_alignment_summary = file.path(paths$results_qc, "GSE42861_processed_matrix_preview_alignment_summary.csv")
)

if (!file.exists(metadata_input)) {
  stop(
    "Metadata cohort file not found at ", metadata_input, ". ",
    "Run scripts/01_download_or_import_data.R first.",
    call. = FALSE
  )
}

if (!file.exists(preview_object_input)) {
  stop(
    "Processed preview object not found at ", preview_object_input, ". ",
    "Run scripts/01_download_or_import_data.R with preview import enabled first.",
    call. = FALSE
  )
}

cohort_metadata <- readr::read_csv(metadata_input, show_col_types = FALSE)
preview_object <- readRDS(preview_object_input)

if (!all(c("sample_map", "methylation_preview") %in% names(preview_object))) {
  stop(
    "Preview object is missing required elements. Expected 'sample_map' and 'methylation_preview'.",
    call. = FALSE
  )
}

preview_sample_map <- tibble::as_tibble(preview_object$sample_map)
preview_matrix <- tibble::as_tibble(preview_object$methylation_preview)

required_preview_columns <- c("ID_REF")

if (!all(required_preview_columns %in% names(preview_matrix))) {
  stop(
    "Preview matrix is missing the required ID_REF column.",
    call. = FALSE
  )
}

sample_columns <- intersect(preview_sample_map$array_position_id, names(preview_matrix))

if (length(sample_columns) == 0) {
  stop(
    "No sample columns from the preview matrix matched the preview sample map.",
    call. = FALSE
  )
}

preview_matrix_aligned <- preview_matrix |>
  dplyr::select(
    ID_REF,
    dplyr::all_of(sample_columns),
    dplyr::any_of("Pval")
  )

cohort_included <- cohort_metadata |>
  dplyr::filter(include_first_pass) |>
  dplyr::select(
    sample_id,
    case_control_status_reviewed,
    age,
    sex_reviewed,
    smoking_status_reviewed
  )

alignment_table <- preview_sample_map |>
  dplyr::mutate(in_preview_matrix = array_position_id %in% names(preview_matrix_aligned)) |>
  dplyr::left_join(cohort_included, by = "sample_id")

sample_columns_in_matrix <- setdiff(names(preview_matrix_aligned), c("ID_REF", "Pval"))
numeric_preview_matrix <- as.data.frame(preview_matrix_aligned[, sample_columns_in_matrix, drop = FALSE])
numeric_preview_matrix[] <- lapply(numeric_preview_matrix, as.numeric)

probe_missingness <- tibble::tibble(
  ID_REF = preview_matrix_aligned$ID_REF,
  missing_n = rowSums(is.na(numeric_preview_matrix)),
  missing_fraction = rowMeans(is.na(numeric_preview_matrix)),
  mean_beta = rowMeans(numeric_preview_matrix, na.rm = TRUE),
  sd_beta = apply(numeric_preview_matrix, 1, stats::sd, na.rm = TRUE)
)

sample_missingness <- tibble::tibble(
  array_position_id = sample_columns_in_matrix,
  missing_n = vapply(numeric_preview_matrix, function(x) sum(is.na(x)), integer(1)),
  missing_fraction = vapply(numeric_preview_matrix, function(x) mean(is.na(x)), numeric(1)),
  min_signal = vapply(numeric_preview_matrix, function(x) suppressWarnings(min(x, na.rm = TRUE)), numeric(1)),
  median_signal = vapply(numeric_preview_matrix, function(x) stats::median(x, na.rm = TRUE), numeric(1)),
  max_signal = vapply(numeric_preview_matrix, function(x) suppressWarnings(max(x, na.rm = TRUE)), numeric(1))
) |>
  dplyr::left_join(
    alignment_table |>
      dplyr::select(
        sample_id,
        array_position_id,
        case_control_status_reviewed,
        age,
        sex_reviewed,
        smoking_status_reviewed
      ),
    by = "array_position_id"
  )

beta_values <- unlist(numeric_preview_matrix, use.names = FALSE)
finite_beta_values <- beta_values[is.finite(beta_values)]
beta_out_of_unit_interval_n <- sum(finite_beta_values < 0 | finite_beta_values > 1)

preview_qc_summary <- tibble::tibble(
  metric = c(
    "dataset_accession",
    "preview_probe_count",
    "preview_sample_count",
    "preview_has_pval_column",
    "aligned_metadata_sample_count",
    "unaligned_preview_sample_count",
    "beta_non_missing_count",
    "beta_missing_count",
    "beta_min",
    "beta_median",
    "beta_max",
    "beta_out_of_unit_interval_n"
  ),
  value = c(
    "GSE42861",
    as.character(nrow(preview_matrix_aligned)),
    as.character(length(sample_columns_in_matrix)),
    as.character("Pval" %in% names(preview_matrix_aligned)),
    as.character(sum(!is.na(alignment_table$case_control_status_reviewed))),
    as.character(sum(!alignment_table$in_preview_matrix)),
    as.character(length(finite_beta_values)),
    as.character(sum(is.na(beta_values))),
    as.character(min(finite_beta_values, na.rm = TRUE)),
    as.character(stats::median(finite_beta_values, na.rm = TRUE)),
    as.character(max(finite_beta_values, na.rm = TRUE)),
    as.character(beta_out_of_unit_interval_n)
  )
)

preview_alignment_summary <- dplyr::bind_rows(
  alignment_table |>
    dplyr::count(
      summary_type = "in_preview_matrix",
      summary_value = ifelse(in_preview_matrix, "yes", "no"),
      name = "n"
    ),
  alignment_table |>
    dplyr::count(
      summary_type = "case_control_status_reviewed",
      summary_value = case_control_status_reviewed,
      name = "n"
    ),
  alignment_table |>
    dplyr::count(
      summary_type = "smoking_status_reviewed_missing",
      summary_value = ifelse(is.na(smoking_status_reviewed), "missing", "present"),
      name = "n"
    )
)

preprocessing_route <- tibble::tibble(
  decision_area = c(
    "dataset_accession",
    "platform",
    "raw_idat_available",
    "processed_matrix_available",
    "processed_matrix_preview_available",
    "recommended_first_pass_entry",
    "why_this_entry_is_preferred",
    "raw_idat_role_later"
  ),
  value = c(
    "GSE42861",
    "Illumina HumanMethylation450 BeadChip",
    "yes",
    "yes",
    "yes",
    "processed_matrix",
    "keeps the first portfolio analysis smaller and easier to explain while metadata, cohort definition, and modelling strategy are still being finalized",
    "raw IDAT workflow can be added later as a stronger preprocessing extension once the initial processed-matrix pipeline is stable"
  )
)

probe_filtering_plan <- tibble::tibble(
  filtering_step = c(
    "Confirm that the preview matrix sample columns align to the selected cohort",
    "Check whether the preview values stay within the expected beta-value range",
    "Review probe-level missingness across the preview rows",
    "Review sample-level missingness across the preview columns",
    "Check whether the processed matrix has already undergone source-side filtering",
    "Record whether low-quality probe filtering can be reproduced from available files",
    "Plan handling of SNP-affected or cross-reactive probes if probe-level annotation is available",
    "Decide how sex chromosome probes will be handled in a blood case-control setting",
    "Separate what is inherited from GEO processing versus what is done in this repository"
  ),
  applies_if_processed_matrix_start = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
  applies_if_raw_idat_start = c(FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE),
  status = c("complete", "complete", "complete", "complete", "pending", "pending", "pending", "pending", "pending"),
  notes = c(
    "Preview import provides a concrete early alignment check before full matrix import",
    "Processed methylation values should remain in the unit interval if they are beta values",
    "Preview missingness is descriptive only and not yet a full probe QC decision",
    "Preview missingness is descriptive only and not yet a full sample exclusion decision",
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
    "preview_qc_completed",
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
    "yes",
    "inherit source-provided processed values for first-pass analysis; postpone array-level normalization decisions until raw IDAT workflow is in scope",
    "the current project priority is to confirm metadata alignment and basic matrix structure before attempting a larger preprocessing build",
    "yes",
    file.path("data", "processed", "GSE42861_methylation_processed.rds"),
    "if the first pass starts from processed values, preprocessing provenance must be described cautiously and not overstated as fully reproduced"
  )
)

readr::write_csv(preprocessing_route, filtering_files$preprocessing_route)
readr::write_csv(probe_filtering_plan, filtering_files$filtering_decisions)
readr::write_csv(normalisation_plan, filtering_files$normalisation_plan)
readr::write_csv(preview_qc_summary, filtering_files$preview_qc_summary)
readr::write_csv(probe_missingness, filtering_files$preview_probe_missingness)
readr::write_csv(sample_missingness, filtering_files$preview_sample_missingness)
readr::write_csv(preview_alignment_summary, filtering_files$preview_alignment_summary)

writeLines(
  c(
    "GSE42861 probe filtering and normalisation notes",
    "",
    "This script does not run full probe filtering or normalization yet.",
    "It reads the processed-matrix preview object generated in scripts/01_download_or_import_data.R and uses it for a first matrix-aware QC pass.",
    "Preview-based checks are intended to confirm sample alignment, basic beta-value range behavior, and obvious missingness patterns before a full matrix import is attempted.",
    "These outputs are descriptive preparation artifacts, not final preprocessing decisions.",
    "Any first-pass analysis that uses processed values should clearly state that preprocessing was inherited from the GEO-provided matrix rather than fully reproduced from raw arrays.",
    "A later extension can switch to the raw IDAT archive to support detection p-values, bead-count filtering, and explicit normalization choices."
  ),
  con = filtering_files$filtering_notes
)

print(preprocessing_route)
print(probe_filtering_plan)
print(normalisation_plan)
print(preview_qc_summary)

# Notes:
# - This step now reads a small processed-matrix preview and writes descriptive QC summaries.
# - No full-matrix import, probe filtering, or normalization is performed here.
