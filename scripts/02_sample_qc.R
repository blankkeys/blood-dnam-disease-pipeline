# Script: 02_sample_qc.R
# Purpose: Perform a metadata-focused QC pass for the first-pass GSE42861 analysis cohort
# Expected inputs: Cohort metadata produced by scripts/01_download_or_import_data.R
# Outputs: Cohort-aware QC summaries and notes in results/qc

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

metadata_input <- file.path(paths$data_metadata, "GSE42861_analysis_cohort.csv")

qc_files <- list(
  summary_table = file.path(paths$results_qc, "GSE42861_sample_qc_summary.csv"),
  exclusion_log = file.path(paths$results_qc, "GSE42861_sample_exclusion_log.csv"),
  qc_notes = file.path(paths$results_qc, "GSE42861_qc_notes.txt"),
  group_balance = file.path(paths$results_qc, "GSE42861_group_balance_summary.csv"),
  sex_balance = file.path(paths$results_qc, "GSE42861_sex_balance_summary.csv"),
  smoking_balance = file.path(paths$results_qc, "GSE42861_smoking_balance_summary.csv"),
  age_summary = file.path(paths$results_qc, "GSE42861_age_summary.csv")
)

if (!file.exists(metadata_input)) {
  stop(
    "Metadata cohort file not found at ", metadata_input, ". ",
    "Run scripts/01_download_or_import_data.R first.",
    call. = FALSE
  )
}

cohort_metadata <- readr::read_csv(metadata_input, show_col_types = FALSE)

cohort_metadata <- cohort_metadata |>
  dplyr::mutate(
    include_first_pass = as.logical(include_first_pass),
    smoking_missing_flag = as.logical(smoking_missing_flag),
    age_missing_flag = as.logical(age_missing_flag),
    sex_missing_flag = as.logical(sex_missing_flag)
  )

analysis_metadata <- cohort_metadata |>
  dplyr::filter(include_first_pass)

qc_checklist <- tibble::tibble(
  qc_step = c(
    "Confirm cohort inclusion counts",
    "Check case/control balance",
    "Check sex balance by group",
    "Check smoking-category balance by group",
    "Summarize age distribution by group",
    "Document missingness relevant to future covariates",
    "Document exclusions and unresolved issues"
  ),
  required_before_modelling = c(TRUE, TRUE, TRUE, TRUE, TRUE, TRUE, TRUE),
  status = c("complete", "complete", "complete", "complete", "complete", "complete", "pending"),
  notes = c(
    "Derived from metadata cohort file",
    "Uses reviewed case/control labels",
    "Uses reviewed sex labels",
    "Uses reviewed smoking labels",
    "Age summary is descriptive only",
    "Smoking missingness remains flagged for 2 samples",
    "No samples excluded at this metadata-only stage"
  )
)

sample_qc_summary <- tibble::tibble(
  metric = c(
    "dataset_accession",
    "metadata_rows_total",
    "analysis_rows_included",
    "samples_cases",
    "samples_controls",
    "age_missing_n",
    "sex_missing_n",
    "smoking_missing_n",
    "raw_array_metrics_available",
    "sex_check_possible"
  ),
  value = c(
    "GSE42861",
    as.character(nrow(cohort_metadata)),
    as.character(nrow(analysis_metadata)),
    as.character(sum(analysis_metadata$case_control_status_reviewed == "case", na.rm = TRUE)),
    as.character(sum(analysis_metadata$case_control_status_reviewed == "control", na.rm = TRUE)),
    as.character(sum(analysis_metadata$age_missing_flag, na.rm = TRUE)),
    as.character(sum(analysis_metadata$sex_missing_flag, na.rm = TRUE)),
    as.character(sum(analysis_metadata$smoking_missing_flag, na.rm = TRUE)),
    "not assessed in metadata-only QC",
    "not assessed without methylation-derived sex checks"
  )
)

sample_exclusion_log <- tibble::tibble(
  sample_id = character(),
  exclusion_stage = character(),
  exclusion_reason = character(),
  decision_recorded_by = character(),
  decision_date = character(),
  notes = character()
)

group_balance_summary <- analysis_metadata |>
  dplyr::count(case_control_status_reviewed, name = "n") |>
  dplyr::rename(group = case_control_status_reviewed)

sex_balance_summary <- analysis_metadata |>
  dplyr::count(case_control_status_reviewed, sex_reviewed, name = "n") |>
  dplyr::rename(group = case_control_status_reviewed, sex = sex_reviewed)

smoking_balance_summary <- analysis_metadata |>
  dplyr::count(case_control_status_reviewed, smoking_status_reviewed, name = "n", .drop = FALSE) |>
  dplyr::rename(group = case_control_status_reviewed, smoking_status = smoking_status_reviewed)

age_summary <- analysis_metadata |>
  dplyr::group_by(case_control_status_reviewed) |>
  dplyr::summarise(
    n = dplyr::n(),
    age_min = min(age, na.rm = TRUE),
    age_median = stats::median(age, na.rm = TRUE),
    age_mean = mean(age, na.rm = TRUE),
    age_max = max(age, na.rm = TRUE),
    .groups = "drop"
  ) |>
  dplyr::rename(group = case_control_status_reviewed)

readr::write_csv(sample_qc_summary, qc_files$summary_table)
readr::write_csv(sample_exclusion_log, qc_files$exclusion_log)
readr::write_csv(group_balance_summary, qc_files$group_balance)
readr::write_csv(sex_balance_summary, qc_files$sex_balance)
readr::write_csv(smoking_balance_summary, qc_files$smoking_balance)
readr::write_csv(age_summary, qc_files$age_summary)

writeLines(
  c(
    "GSE42861 metadata QC notes",
    "",
    "This QC step summarizes metadata only and does not inspect methylation intensities or array control metrics.",
    "All 689 samples with reviewed case/control labels are included in the initial cohort.",
    "Smoking status is missing for 2 included samples and should be handled explicitly in downstream design decisions.",
    "No treatment, medication, subtype, or obvious batch fields were available in the parsed sample metadata."
  ),
  con = qc_files$qc_notes
)

print(qc_checklist)
print(sample_qc_summary)

# Notes:
# - This script does not perform methylation-level QC.
# - These summaries are intended to guide cohort review and downstream covariate planning.
