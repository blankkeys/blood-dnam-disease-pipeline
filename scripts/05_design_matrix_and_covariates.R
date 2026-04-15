# Script: 05_design_matrix_and_covariates.R
# Purpose: Build a metadata-driven first-pass design and covariate planning step for GSE42861
# Expected inputs: Cohort metadata produced by scripts/01_download_or_import_data.R and reviewed via scripts/02_sample_qc.R
# Outputs: Dataset-specific design planning files and covariate review summaries for downstream EWAS setup

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

metadata_input <- file.path(paths$data_metadata, "GSE42861_analysis_cohort.csv")

design_files <- list(
  design_plan = file.path(paths$data_metadata, "GSE42861_design_matrix_plan.csv"),
  covariate_review = file.path(paths$results_qc, "GSE42861_covariate_review.csv"),
  model_cohort = file.path(paths$data_metadata, "GSE42861_model_cohort.csv"),
  design_notes = file.path(paths$results_qc, "GSE42861_design_matrix_notes.txt")
)

if (!file.exists(metadata_input)) {
  stop(
    "Metadata cohort file not found at ", metadata_input, ". ",
    "Run scripts/01_download_or_import_data.R first.",
    call. = FALSE
  )
}

cohort_metadata <- readr::read_csv(metadata_input, show_col_types = FALSE) |>
  dplyr::mutate(
    include_first_pass = as.logical(include_first_pass),
    smoking_missing_flag = as.logical(smoking_missing_flag),
    age_missing_flag = as.logical(age_missing_flag),
    sex_missing_flag = as.logical(sex_missing_flag)
  )

model_cohort <- cohort_metadata |>
  dplyr::filter(include_first_pass) |>
  dplyr::mutate(
    case_control_status_reviewed = factor(
      case_control_status_reviewed,
      levels = c("control", "case")
    ),
    sex_reviewed = factor(
      sex_reviewed,
      levels = c("female", "male")
    ),
    smoking_status_reviewed = factor(
      smoking_status_reviewed,
      levels = c("never", "former", "current", "occasional")
    )
  )

design_matrix_plan <- tibble::tibble(
  decision_area = c(
    "dataset_accession",
    "analysis_rows_included",
    "primary_outcome_variable",
    "reference_group",
    "comparison_of_interest",
    "candidate_covariates",
    "smoking_handling_plan",
    "cell_composition_included",
    "batch_adjustment_strategy",
    "model_formula_draft",
    "sensitivity_analysis_plan"
  ),
  value = c(
    "GSE42861",
    as.character(nrow(model_cohort)),
    "case_control_status_reviewed",
    "control",
    "rheumatoid arthritis case versus control",
    "age; sex_reviewed; smoking_status_reviewed",
    "2 samples have missing smoking; keep in cohort and decide later between complete-case smoking-adjusted model or smoking sensitivity analysis",
    "not yet available",
    "no clear batch variable identified in parsed GEO metadata",
    "M_value ~ case_control_status_reviewed + age + sex_reviewed (+ smoking_status_reviewed in adjusted/sensitivity models)",
    "compare a basic age+sex model against a smoking-adjusted subset if smoking is used"
  )
)

covariate_review <- tibble::tibble(
  variable_name = c(
    "case_control_status_reviewed",
    "age",
    "sex_reviewed",
    "smoking_status_reviewed",
    "cell_type",
    "platform_id",
    "treatment_status",
    "batch"
  ),
  available = c(
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    FALSE,
    FALSE
  ),
  coding_checked = c(
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    FALSE,
    FALSE
  ),
  missingness_reviewed = c(
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    FALSE,
    FALSE
  ),
  planned_for_model = c(
    TRUE,
    TRUE,
    TRUE,
    TRUE,
    FALSE,
    FALSE,
    FALSE,
    FALSE
  ),
  notes = c(
    "Core outcome variable; 354 cases and 335 controls",
    "No missing values in first-pass cohort",
    "No missing values in first-pass cohort",
    "2 missing values; keep under review before final model specification",
    "Uniform PBL source; not a useful adjustment variable within this cohort",
    "Uniform GPL13534 platform; not a useful adjustment variable within this cohort",
    "Not found in parsed GEO sample metadata",
    "Not found in parsed GEO sample metadata"
  )
)

readr::write_csv(design_matrix_plan, design_files$design_plan)
readr::write_csv(covariate_review, design_files$covariate_review)
readr::write_csv(model_cohort, design_files$model_cohort)

writeLines(
  c(
    "GSE42861 design matrix notes",
    "",
    "This step defines candidate outcome and covariates from metadata only and does not build the final methylation model matrix yet.",
    "The first-pass cohort contains 689 samples with valid case/control labels.",
    "Age and sex appear complete in the current cohort metadata.",
    "Smoking is present for most samples but missing for 2 controls; this should be handled explicitly in downstream modelling.",
    "No treatment, medication, subtype, or batch variable was identified in the parsed GEO sample metadata.",
    "A sensible first-pass strategy is to start with a simple age+sex-adjusted case-control comparison, then assess whether smoking should enter as a subset-based sensitivity adjustment."
  ),
  con = design_files$design_notes
)

print(design_matrix_plan)
print(covariate_review)

# Notes:
# - This script prepares covariate choices from metadata only.
# - It does not construct a methylation design matrix until the methylation object is available.
