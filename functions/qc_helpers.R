# Helper file: qc_helpers.R
# Purpose: Starter location for sample and probe QC helper functions
# Expected inputs: Methylation objects, metadata, and QC thresholds
# Outputs: Reusable QC summaries, flags, and helper plots

write_csv_if_missing <- function(data, path) {
  if (!file.exists(path)) {
    readr::write_csv(data, path)
  }

  invisible(path)
}

check_required_metadata_columns <- function(metadata, required_columns) {
  missing_columns <- setdiff(required_columns, names(metadata))

  tibble::tibble(
    column_name = required_columns,
    present = required_columns %in% names(metadata)
  ) |>
    dplyr::mutate(
      missing_count = length(missing_columns)
    )
}

standard_qc_metadata_fields <- function() {
  c(
    "sample_id",
    "group",
    "age",
    "sex",
    "smoking_status",
    "treatment_status",
    "batch"
  )
}

# TODO: Add array-specific QC helpers after the final platform and input object class are confirmed.
