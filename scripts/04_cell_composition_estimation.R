# Script: 04_cell_composition_estimation.R
# Purpose: Set up a documented strategy for handling blood cell-composition effects
# Expected inputs: Processed methylation object, sample metadata, and platform information
# Outputs: Cell-composition planning files and starter templates for downstream interpretation

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

cell_comp_files <- list(
  estimation_plan = file.path(paths$data_metadata, "cell_composition_plan.csv"),
  cell_comp_notes = file.path(paths$results_qc, "cell_composition_notes.txt"),
  cell_comp_template = file.path(paths$data_processed, "cell_composition_estimates_template.csv")
)

cell_composition_plan <- tibble::tibble(
  decision_area = c(
    "sample_source",
    "reference_based_estimation_feasible",
    "candidate_method",
    "required_inputs",
    "case_control_imbalance_check",
    "planned_use_in_models"
  ),
  value = c(
    "whole blood or peripheral blood to be confirmed",
    NA_character_,
    NA_character_,
    "processed methylation object plus compatible reference framework",
    "compare estimated proportions by group before modelling",
    "consider as covariates or interpretive sensitivity check"
  )
)

cell_composition_template <- tibble::tibble(
  sample_id = character(),
  cell_type = character(),
  estimated_proportion = numeric(),
  estimation_method = character(),
  notes = character()
)

write_csv_if_missing(cell_composition_plan, cell_comp_files$estimation_plan)
write_csv_if_missing(cell_composition_template, cell_comp_files$cell_comp_template)

if (!file.exists(cell_comp_files$cell_comp_notes)) {
  writeLines(
    c(
      "Cell composition notes",
      "",
      "Use this file to record whether cell estimation is feasible for the selected dataset and how estimates will be used downstream.",
      "If estimation is not possible, note how this limitation affects interpretation."
    ),
    con = cell_comp_files$cell_comp_notes
  )
}

print(cell_composition_plan)

# TODO: Confirm that the selected dataset uses blood-derived samples suitable for cell mixture considerations.
# TODO: Determine whether reference-based estimation is supported for the final array platform and input format.
# TODO: Add code to calculate cell estimates only after preprocessing choices are finalized.
# TODO: Summarize case-control differences in estimated cell proportions before EWAS modelling.
# TODO: Carry the chosen strategy into the design-matrix step with explicit documentation.

# Interpretation reminder:
# Cell mixture can dominate apparent disease-associated signals in blood.
