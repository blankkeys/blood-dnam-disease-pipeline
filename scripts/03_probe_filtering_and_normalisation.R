# Script: 03_probe_filtering_and_normalisation.R
# Purpose: Run preview-based QC and support a first full processed-matrix import for GSE42861 before any downstream EWAS
# Expected inputs: GSE42861 cohort metadata, processed-matrix sample map, processed-matrix archive, and the preview object created upstream
# Outputs: Dataset-specific preprocessing plans, preview/full import summaries, and a project-ready processed methylation object in data/processed

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

dataset_config <- list(
  accession = "GSE42861",
  processed_matrix_filename = "GSE42861_processed_methylation_matrix.txt.gz",
  import_full_processed_matrix = TRUE,
  expected_sample_n = 689L,
  notes = c(
    "This step uses the GEO processed methylation matrix as the first-pass data entry route.",
    "It aligns imported sample columns to the reviewed analysis cohort before saving a project-ready object.",
    "It does not claim full raw-array preprocessing or final probe filtering."
  )
)

metadata_input <- file.path(paths$data_metadata, paste0(dataset_config$accession, "_analysis_cohort.csv"))
sample_map_input <- file.path(paths$data_metadata, paste0(dataset_config$accession, "_processed_matrix_sample_map.csv"))
processed_matrix_input <- file.path(paths$data_raw, dataset_config$processed_matrix_filename)
preview_object_input <- file.path(paths$data_processed, paste0(dataset_config$accession, "_processed_matrix_preview.rds"))

filtering_files <- list(
  filtering_decisions = file.path(paths$results_qc, paste0(dataset_config$accession, "_probe_filtering_decisions.csv")),
  filtering_notes = file.path(paths$results_qc, paste0(dataset_config$accession, "_probe_filtering_notes.txt")),
  normalisation_plan = file.path(paths$data_metadata, paste0(dataset_config$accession, "_normalisation_plan.csv")),
  preprocessing_route = file.path(paths$data_metadata, paste0(dataset_config$accession, "_preprocessing_route.csv")),
  preview_qc_summary = file.path(paths$results_qc, paste0(dataset_config$accession, "_processed_matrix_preview_qc_summary.csv")),
  preview_probe_missingness = file.path(paths$results_qc, paste0(dataset_config$accession, "_processed_matrix_preview_probe_missingness.csv")),
  preview_sample_missingness = file.path(paths$results_qc, paste0(dataset_config$accession, "_processed_matrix_preview_sample_missingness.csv")),
  preview_alignment_summary = file.path(paths$results_qc, paste0(dataset_config$accession, "_processed_matrix_preview_alignment_summary.csv")),
  full_import_summary = file.path(paths$results_qc, paste0(dataset_config$accession, "_processed_matrix_import_summary.csv")),
  full_import_sample_summary = file.path(paths$results_qc, paste0(dataset_config$accession, "_processed_matrix_import_sample_summary.csv")),
  full_import_object = file.path(paths$data_processed, paste0(dataset_config$accession, "_methylation_processed.rds"))
)

required_inputs <- c(metadata_input, sample_map_input, processed_matrix_input, preview_object_input)
missing_inputs <- required_inputs[!file.exists(required_inputs)]

if (length(missing_inputs) > 0) {
  stop(
    "Required input files are missing:\n",
    paste(missing_inputs, collapse = "\n"),
    "\nRun scripts/01_download_or_import_data.R first.",
    call. = FALSE
  )
}

read_processed_matrix <- function(gz_path) {
  utils::read.delim(
    gzfile(gz_path, open = "rt"),
    header = TRUE,
    sep = "\t",
    check.names = FALSE,
    stringsAsFactors = FALSE
  )
}

align_imported_matrix_to_cohort <- function(imported_matrix, sample_map, cohort_metadata) {
  included_cohort <- cohort_metadata |>
    dplyr::filter(include_first_pass) |>
    dplyr::select(
      sample_id,
      sample_label,
      case_control_status_reviewed,
      age,
      sex_reviewed,
      smoking_status_reviewed
    )

  mapped_samples <- sample_map |>
    dplyr::filter(present_in_processed_matrix) |>
    dplyr::semi_join(included_cohort, by = "sample_id") |>
    dplyr::mutate(in_imported_matrix = array_position_id %in% names(imported_matrix))

  missing_from_matrix <- mapped_samples |>
    dplyr::filter(!in_imported_matrix)

  if (nrow(missing_from_matrix) > 0) {
    stop(
      "The full processed matrix is missing ", nrow(missing_from_matrix),
      " cohort-aligned sample columns. Review the processed-matrix sample map before proceeding.",
      call. = FALSE
    )
  }

  ordered_sample_map <- mapped_samples |>
    dplyr::inner_join(included_cohort, by = c("sample_id", "sample_label")) |>
    dplyr::arrange(match(array_position_id, names(imported_matrix)))

  aligned_matrix <- imported_matrix |>
    dplyr::select(
      ID_REF,
      dplyr::all_of(ordered_sample_map$array_position_id),
      dplyr::any_of("Pval")
    )

  list(
    aligned_matrix = aligned_matrix,
    aligned_sample_map = ordered_sample_map
  )
}

build_preview_qc_outputs <- function(preview_matrix_aligned, alignment_table) {
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
      dataset_config$accession,
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

  list(
    preview_qc_summary = preview_qc_summary,
    probe_missingness = probe_missingness,
    sample_missingness = sample_missingness,
    preview_alignment_summary = preview_alignment_summary
  )
}

build_full_import_summary <- function(aligned_matrix, aligned_sample_map) {
  sample_columns <- setdiff(names(aligned_matrix), c("ID_REF", "Pval"))
  numeric_matrix <- as.data.frame(aligned_matrix[, sample_columns, drop = FALSE])
  numeric_matrix[] <- lapply(numeric_matrix, as.numeric)

  beta_values <- unlist(numeric_matrix, use.names = FALSE)
  finite_beta_values <- beta_values[is.finite(beta_values)]

  import_summary <- tibble::tibble(
    metric = c(
      "dataset_accession",
      "imported_probe_count",
      "imported_sample_count",
      "import_has_pval_column",
      "aligned_sample_count",
      "case_n",
      "control_n",
      "beta_non_missing_count",
      "beta_missing_count",
      "beta_min",
      "beta_median",
      "beta_max",
      "beta_out_of_unit_interval_n"
    ),
    value = c(
      dataset_config$accession,
      as.character(nrow(aligned_matrix)),
      as.character(length(sample_columns)),
      as.character("Pval" %in% names(aligned_matrix)),
      as.character(nrow(aligned_sample_map)),
      as.character(sum(aligned_sample_map$case_control_status_reviewed == "case", na.rm = TRUE)),
      as.character(sum(aligned_sample_map$case_control_status_reviewed == "control", na.rm = TRUE)),
      as.character(length(finite_beta_values)),
      as.character(sum(is.na(beta_values))),
      as.character(min(finite_beta_values, na.rm = TRUE)),
      as.character(stats::median(finite_beta_values, na.rm = TRUE)),
      as.character(max(finite_beta_values, na.rm = TRUE)),
      as.character(sum(finite_beta_values < 0 | finite_beta_values > 1))
    )
  )

  import_sample_summary <- aligned_sample_map |>
    dplyr::count(
      case_control_status_reviewed,
      sex_reviewed,
      smoking_status_reviewed,
      name = "n",
      .drop = FALSE
    )

  list(
    import_summary = import_summary,
    import_sample_summary = import_sample_summary
  )
}

cohort_metadata <- readr::read_csv(metadata_input, show_col_types = FALSE)
sample_map <- readr::read_csv(sample_map_input, show_col_types = FALSE)
preview_object <- readRDS(preview_object_input)

if (!all(c("sample_map", "methylation_preview") %in% names(preview_object))) {
  stop(
    "Preview object is missing required elements. Expected 'sample_map' and 'methylation_preview'.",
    call. = FALSE
  )
}

preview_sample_map <- tibble::as_tibble(preview_object$sample_map)
preview_matrix <- tibble::as_tibble(preview_object$methylation_preview)

if (!"ID_REF" %in% names(preview_matrix)) {
  stop("Preview matrix is missing the required ID_REF column.", call. = FALSE)
}

preview_sample_columns <- intersect(preview_sample_map$array_position_id, names(preview_matrix))

if (length(preview_sample_columns) == 0) {
  stop(
    "No sample columns from the preview matrix matched the preview sample map.",
    call. = FALSE
  )
}

preview_matrix_aligned <- preview_matrix |>
  dplyr::select(
    ID_REF,
    dplyr::all_of(preview_sample_columns),
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

preview_alignment_table <- preview_sample_map |>
  dplyr::mutate(in_preview_matrix = array_position_id %in% names(preview_matrix_aligned)) |>
  dplyr::left_join(cohort_included, by = "sample_id")

preview_outputs <- build_preview_qc_outputs(
  preview_matrix_aligned = preview_matrix_aligned,
  alignment_table = preview_alignment_table
)

preprocessing_route <- tibble::tibble(
  decision_area = c(
    "dataset_accession",
    "platform",
    "raw_idat_available",
    "processed_matrix_available",
    "processed_matrix_preview_available",
    "full_processed_matrix_import_enabled",
    "recommended_first_pass_entry",
    "why_this_entry_is_preferred",
    "raw_idat_role_later"
  ),
  value = c(
    dataset_config$accession,
    "Illumina HumanMethylation450 BeadChip",
    "yes",
    "yes",
    "yes",
    ifelse(dataset_config$import_full_processed_matrix, "yes", "no"),
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
    "Import the full processed matrix and align it to the selected cohort",
    "Check whether the full imported values stay within the expected beta-value range",
    "Check whether the processed matrix has already undergone source-side filtering",
    "Record whether low-quality probe filtering can be reproduced from available files",
    "Plan handling of SNP-affected or cross-reactive probes if probe-level annotation is available",
    "Decide how sex chromosome probes will be handled in a blood case-control setting",
    "Separate what is inherited from GEO processing versus what is done in this repository"
  ),
  applies_if_processed_matrix_start = rep(TRUE, 11),
  applies_if_raw_idat_start = c(FALSE, FALSE, FALSE, FALSE, FALSE, FALSE, TRUE, TRUE, TRUE, TRUE, TRUE),
  status = c("complete", "complete", "complete", "complete", "complete", "complete", "pending", "pending", "pending", "pending", "pending"),
  notes = c(
    "Preview import provides a concrete early alignment check before full matrix import",
    "Processed methylation values should remain in the unit interval if they are beta values",
    "Preview missingness is descriptive only and not yet a full probe QC decision",
    "Preview missingness is descriptive only and not yet a full sample exclusion decision",
    "The full processed matrix is aligned to the reviewed first-pass cohort before saving the project-ready object",
    "This is a structure check, not proof that preprocessing is fully reproduced",
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
    "full_processed_matrix_import_completed",
    "candidate_normalisation_method",
    "reason_for_method_choice",
    "sensitivity_analysis_needed",
    "processed_object_output",
    "interpretation_limit"
  ),
  value = c(
    dataset_config$accession,
    "processed_matrix_first_pass",
    "Illumina HumanMethylation450 BeadChip",
    "yes",
    ifelse(dataset_config$import_full_processed_matrix, "planned_in_this_script", "no"),
    "inherit source-provided processed values for first-pass analysis; postpone array-level normalization decisions until raw IDAT workflow is in scope",
    "the current project priority is to confirm metadata alignment and basic matrix structure before attempting a larger preprocessing build",
    "yes",
    file.path("data", "processed", paste0(dataset_config$accession, "_methylation_processed.rds")),
    "if the first pass starts from processed values, preprocessing provenance must be described cautiously and not overstated as fully reproduced"
  )
)

readr::write_csv(preprocessing_route, filtering_files$preprocessing_route)
readr::write_csv(probe_filtering_plan, filtering_files$filtering_decisions)
readr::write_csv(normalisation_plan, filtering_files$normalisation_plan)
readr::write_csv(preview_outputs$preview_qc_summary, filtering_files$preview_qc_summary)
readr::write_csv(preview_outputs$probe_missingness, filtering_files$preview_probe_missingness)
readr::write_csv(preview_outputs$sample_missingness, filtering_files$preview_sample_missingness)
readr::write_csv(preview_outputs$preview_alignment_summary, filtering_files$preview_alignment_summary)

if (dataset_config$import_full_processed_matrix) {
  imported_matrix <- read_processed_matrix(processed_matrix_input)

  if (!"ID_REF" %in% names(imported_matrix)) {
    stop("The full processed matrix is missing the required ID_REF column.", call. = FALSE)
  }

  aligned_import <- align_imported_matrix_to_cohort(
    imported_matrix = tibble::as_tibble(imported_matrix),
    sample_map = sample_map,
    cohort_metadata = cohort_metadata
  )

  if (nrow(aligned_import$aligned_sample_map) != dataset_config$expected_sample_n) {
    stop(
      "Aligned full import contains ", nrow(aligned_import$aligned_sample_map),
      " samples, but ", dataset_config$expected_sample_n, " were expected for the first-pass cohort.",
      call. = FALSE
    )
  }

  full_import_outputs <- build_full_import_summary(
    aligned_matrix = aligned_import$aligned_matrix,
    aligned_sample_map = aligned_import$aligned_sample_map
  )

  saveRDS(
    list(
      dataset_accession = dataset_config$accession,
      source_type = "GEO_processed_matrix",
      preprocessing_level = "source_processed_values",
      notes = dataset_config$notes,
      sample_metadata = aligned_import$aligned_sample_map,
      methylation_matrix = aligned_import$aligned_matrix
    ),
    filtering_files$full_import_object
  )

  readr::write_csv(full_import_outputs$import_summary, filtering_files$full_import_summary)
  readr::write_csv(full_import_outputs$import_sample_summary, filtering_files$full_import_sample_summary)
}

writeLines(
  c(
    "GSE42861 probe filtering and normalisation notes",
    "",
    "This script uses the processed-matrix preview for early matrix-aware QC and can also import the full processed matrix.",
    "The full processed import is intended to create a project-ready methylation object aligned to the reviewed first-pass cohort.",
    "These outputs are still preparation artifacts and do not amount to fully reproduced raw-array preprocessing.",
    "Any first-pass analysis that uses processed values should clearly state that preprocessing was inherited from the GEO-provided matrix rather than fully reproduced from raw arrays.",
    "A later extension can switch to the raw IDAT archive to support detection p-values, bead-count filtering, and explicit normalization choices."
  ),
  con = filtering_files$filtering_notes
)

print(preprocessing_route)
print(probe_filtering_plan)
print(normalisation_plan)
print(preview_outputs$preview_qc_summary)
if (dataset_config$import_full_processed_matrix) {
  print(readr::read_csv(filtering_files$full_import_summary, show_col_types = FALSE))
}

# Notes:
# - This step now reads the processed-matrix preview and can import the full processed matrix.
# - No raw-IDAT preprocessing, probe filtering, or normalization is performed here.
