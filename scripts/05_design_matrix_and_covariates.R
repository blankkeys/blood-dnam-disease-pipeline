# Script: 05_design_matrix_and_covariates.R
# Purpose: Set up a transparent strategy for phenotype coding, covariates, and design matrices
# Expected inputs: Processed methylation object, cleaned phenotype data, and documented covariates
# Outputs: Design-planning tables, covariate notes, and starter model specification files

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

design_files <- list(
  design_plan = file.path(paths$data_metadata, "design_matrix_plan.csv"),
  covariate_review = file.path(paths$results_qc, "covariate_review.csv"),
  design_notes = file.path(paths$results_qc, "design_matrix_notes.txt")
)

design_matrix_plan <- tibble::tibble(
  decision_area = c(
    "primary_outcome_variable",
    "reference_group",
    "comparison_of_interest",
    "candidate_covariates",
    "cell_composition_included",
    "batch_adjustment_strategy",
    "model_formula_draft"
  ),
  value = c(
    NA_character_,
    NA_character_,
    NA_character_,
    "age; sex; smoking_status; treatment_status; batch",
    NA_character_,
    NA_character_,
    NA_character_
  )
)

covariate_review <- tibble::tibble(
  variable_name = c(
    "group",
    "age",
    "sex",
    "smoking_status",
    "treatment_status",
    "batch",
    "cell_composition_estimates"
  ),
  available = NA,
  coding_checked = FALSE,
  missingness_reviewed = FALSE,
  planned_for_model = NA,
  notes = ""
)

write_csv_if_missing(design_matrix_plan, design_files$design_plan)
write_csv_if_missing(covariate_review, design_files$covariate_review)

if (!file.exists(design_files$design_notes)) {
  writeLines(
    c(
      "Design matrix notes",
      "",
      "Use this file to document coding choices, reference levels, exclusions, and formula decisions.",
      "Keep the primary comparison simple and justify every adjustment variable."
    ),
    con = design_files$design_notes
  )
}

print(design_matrix_plan)

# TODO: Load cleaned sample metadata once dataset-specific import files exist.
# TODO: Confirm case and control labels and define the main contrast explicitly.
# TODO: Review each covariate for missingness, coding consistency, and plausibility.
# TODO: Decide whether estimated cell proportions belong in the main model or a sensitivity analysis.
# TODO: Create the final model matrix only after metadata cleaning is complete.
