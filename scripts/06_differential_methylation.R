# Script: 06_differential_methylation.R
# Purpose: Define a cautious starter workflow for EWAS-style differential methylation analysis
# Expected inputs: Normalized methylation data, finalized design matrix, and documented contrast definitions
# Outputs: Analysis planning tables and starter result-file templates in results/differential_methylation

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

dm_files <- list(
  analysis_plan = file.path(paths$results_dm, "differential_methylation_plan.csv"),
  result_columns = file.path(paths$results_dm, "result_column_dictionary.csv"),
  analysis_notes = file.path(paths$results_dm, "differential_methylation_notes.txt")
)

differential_methylation_plan <- tibble::tibble(
  decision_area = c(
    "analysis_scale",
    "primary_modelling_framework",
    "main_contrast",
    "multiple_testing_strategy",
    "effect_size_reporting",
    "sensitivity_analysis_planned"
  ),
  value = c(
    "M-values for modelling, beta values for interpretation and plots",
    "limma pipeline to be confirmed after dataset import",
    NA_character_,
    "FDR control",
    "report effect direction and moderated statistics",
    "yes"
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
    "Short note on formula or sensitivity setting"
  )
)

write_csv_if_missing(differential_methylation_plan, dm_files$analysis_plan)
write_csv_if_missing(result_column_dictionary, dm_files$result_columns)

if (!file.exists(dm_files$analysis_notes)) {
  writeLines(
    c(
      "Differential methylation analysis notes",
      "",
      "Use this file to record model choices, contrast definitions, and sensitivity analyses.",
      "Do not describe associations as disease-specific mechanisms without checking major confounders."
    ),
    con = dm_files$analysis_notes
  )
}

print(differential_methylation_plan)

# TODO: Confirm whether the main model will use M-values only or both M-values and beta values.
# TODO: Build the final contrast matrix after the primary comparison is fixed.
# TODO: Save complete result tables before creating filtered or top-hit summaries.
# TODO: Add sensitivity analyses for alternative covariate sets or cell-composition handling if feasible.
# TODO: Keep interpretation separate from model fitting and result export.

# Do not interpret associations as disease-specific effects without confounder checks.
