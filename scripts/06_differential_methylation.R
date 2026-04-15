# Script: 06_differential_methylation.R
# Purpose: Define a metadata-driven first-pass EWAS analysis plan for GSE42861
# Expected inputs: Cohort metadata, design planning outputs, and a future normalized methylation object
# Outputs: Dataset-specific analysis planning files and result table definitions in results/differential_methylation

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

design_input <- file.path(paths$data_metadata, "GSE42861_design_matrix_plan.csv")
covariate_input <- file.path(paths$results_qc, "GSE42861_covariate_review.csv")
cohort_input <- file.path(paths$data_metadata, "GSE42861_model_cohort.csv")

dm_files <- list(
  analysis_plan = file.path(paths$results_dm, "GSE42861_differential_methylation_plan.csv"),
  model_plan = file.path(paths$results_dm, "GSE42861_model_plan.csv"),
  result_columns = file.path(paths$results_dm, "GSE42861_result_column_dictionary.csv"),
  contrast_plan = file.path(paths$results_dm, "GSE42861_contrast_plan.csv"),
  analysis_notes = file.path(paths$results_dm, "GSE42861_differential_methylation_notes.txt")
)

required_inputs <- c(design_input, covariate_input, cohort_input)

missing_inputs <- required_inputs[!file.exists(required_inputs)]

if (length(missing_inputs) > 0) {
  stop(
    "Required planning input files are missing: ",
    paste(missing_inputs, collapse = "; "),
    call. = FALSE
  )
}

design_plan <- readr::read_csv(design_input, show_col_types = FALSE)
covariate_review <- readr::read_csv(covariate_input, show_col_types = FALSE)
model_cohort <- readr::read_csv(cohort_input, show_col_types = FALSE)

smoking_missing_n <- sum(model_cohort$smoking_missing_flag %in% TRUE | model_cohort$smoking_missing_flag == "TRUE", na.rm = TRUE)

differential_methylation_plan <- tibble::tibble(
  decision_area = c(
    "dataset_accession",
    "analysis_scale",
    "primary_modelling_framework",
    "baseline_model",
    "smoking_adjusted_strategy",
    "main_contrast",
    "multiple_testing_strategy",
    "effect_size_reporting",
    "sensitivity_analysis_planned",
    "result_export_policy"
  ),
  value = c(
    "GSE42861",
    "M-values for modelling, beta values for interpretation and plots",
    "limma EWAS workflow once normalized methylation data are available",
    "case_control_status_reviewed + age + sex_reviewed",
    "if smoking is included, use a complete-case smoking-adjusted sensitivity model because 2 samples have missing smoking_status_reviewed",
    "case versus control with control as the reference group",
    "FDR control",
    "report effect direction, moderated statistics, and adjusted p-values",
    "yes",
    "save complete results first, then create filtered summaries"
  )
)

model_plan <- tibble::tibble(
  model_name = c(
    "primary_age_sex_model",
    "smoking_adjusted_sensitivity_model"
  ),
  formula_draft = c(
    "M_value ~ case_control_status_reviewed + age + sex_reviewed",
    "M_value ~ case_control_status_reviewed + age + sex_reviewed + smoking_status_reviewed"
  ),
  cohort_scope = c(
    "all 689 first-pass cohort samples",
    "complete-case subset with non-missing smoking_status_reviewed"
  ),
  rationale = c(
    "simple first-pass confounder-aware model using complete covariates",
    paste0(
      "assess whether smoking materially changes case-control associations; ",
      smoking_missing_n,
      " samples currently have missing smoking"
    )
  )
)

contrast_plan <- tibble::tibble(
  contrast_name = c(
    "case_vs_control_primary",
    "case_vs_control_smoking_adjusted"
  ),
  model_name = c(
    "primary_age_sex_model",
    "smoking_adjusted_sensitivity_model"
  ),
  contrast_definition = c(
    "case_control_status_reviewedcase",
    "case_control_status_reviewedcase"
  ),
  interpretation_note = c(
    "primary case-control contrast in the age+sex-adjusted model",
    "same contrast checked in the smoking-adjusted sensitivity model"
  )
)

result_column_dictionary <- tibble::tibble(
  column_name = c(
    "probe_id",
    "logFC_or_effect",
    "average_expression_or_signal",
    "t_statistic",
    "p_value",
    "adjusted_p_value",
    "contrast",
    "model_name",
    "model_notes"
  ),
  intended_meaning = c(
    "CpG probe identifier",
    "Estimated direction and magnitude of association",
    "Mean modeled signal summary if applicable",
    "Moderated test statistic",
    "Nominal p-value",
    "Multiple-testing adjusted p-value",
    "Named comparison used in the model",
    "Name of the fitted model specification",
    "Short note on formula, subset, or sensitivity setting"
  )
)

readr::write_csv(differential_methylation_plan, dm_files$analysis_plan)
readr::write_csv(model_plan, dm_files$model_plan)
readr::write_csv(contrast_plan, dm_files$contrast_plan)
readr::write_csv(result_column_dictionary, dm_files$result_columns)

writeLines(
  c(
    "GSE42861 differential methylation notes",
    "",
    "This script records the first-pass EWAS modelling plan but does not fit any model yet.",
    "The baseline case-control model should start with age and sex because both are complete in the current cohort metadata.",
    paste0(
      "Smoking is present for most samples but missing for ",
      smoking_missing_n,
      " samples, so smoking is better handled as an explicit sensitivity model rather than silently forcing a cohort change."
    ),
    "No batch, treatment, or cell-composition variable is currently available for the first-pass model.",
    "Interpret any case-control association cautiously because blood methylation signals may still reflect cell mixture or inflammation."
  ),
  con = dm_files$analysis_notes
)

print(differential_methylation_plan)
print(model_plan)
print(contrast_plan)

# Notes:
# - This step defines the modelling strategy only.
# - No methylation values are loaded and no EWAS is run here.
