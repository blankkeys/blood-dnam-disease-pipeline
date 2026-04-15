# Script: 04_cell_composition_estimation.R
# Purpose: Define a dataset-specific cell-composition strategy for GSE42861 before any estimation is run
# Expected inputs: Cohort metadata, preprocessing route decisions, and a future methylation object
# Outputs: GSE42861-specific cell-composition planning files and interpretation notes

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

metadata_input <- file.path(paths$data_metadata, "GSE42861_analysis_cohort.csv")
preprocessing_input <- file.path(paths$data_metadata, "GSE42861_preprocessing_route.csv")

cell_comp_files <- list(
  estimation_plan = file.path(paths$data_metadata, "GSE42861_cell_composition_plan.csv"),
  cell_comp_notes = file.path(paths$results_qc, "GSE42861_cell_composition_notes.txt"),
  cell_comp_template = file.path(paths$data_processed, "GSE42861_cell_composition_estimates_template.csv"),
  modeling_strategy = file.path(paths$results_qc, "GSE42861_cell_composition_modeling_strategy.csv")
)

required_inputs <- c(metadata_input, preprocessing_input)
missing_inputs <- required_inputs[!file.exists(required_inputs)]

if (length(missing_inputs) > 0) {
  stop(
    "Required planning input files are missing: ",
    paste(missing_inputs, collapse = "; "),
    call. = FALSE
  )
}

cohort_metadata <- readr::read_csv(metadata_input, show_col_types = FALSE)
preprocessing_route <- readr::read_csv(preprocessing_input, show_col_types = FALSE)

cell_composition_plan <- tibble::tibble(
  decision_area = c(
    "dataset_accession",
    "sample_source",
    "platform",
    "first_pass_input_level",
    "reference_based_estimation_feasible_now",
    "candidate_method_later",
    "required_inputs",
    "case_control_imbalance_check",
    "planned_use_in_models"
  ),
  value = c(
    "GSE42861",
    "peripheral blood leukocytes",
    "Illumina HumanMethylation450 BeadChip",
    "processed_matrix_first_pass",
    "not yet, because the current first-pass route does not yet establish the exact processed-matrix structure or raw-array preprocessing context",
    "minfi reference-based blood cell estimation after the methylation entry pathway is finalized",
    "processed or raw methylation object with compatible probe structure plus an established estimation workflow",
    "compare estimated cell proportions by case/control group before deciding whether to include them as covariates",
    "treat as a later covariate or sensitivity-analysis layer, not as a silent assumption"
  )
)

cell_composition_modeling_strategy <- tibble::tibble(
  strategy_component = c(
    "first_pass_model_position",
    "why_not_included_yet",
    "future_inclusion_trigger",
    "interpretation_rule_if_absent",
    "sensitivity_analysis_goal"
  ),
  value = c(
    "not included in the current first-pass age+sex baseline model",
    "cell estimates are not yet derived and the first-pass project route currently starts from metadata and processed-matrix planning rather than a finalized estimation-ready methylation object",
    "add once the processed matrix or raw IDAT import is concretely implemented and cell estimation compatibility is confirmed",
    "case-control associations must be discussed as potentially confounded by blood cell mixture",
    "compare baseline results against a cell-adjusted model once estimates are available"
  )
)

cell_composition_template <- tibble::tibble(
  sample_id = character(),
  cell_type = character(),
  estimated_proportion = numeric(),
  estimation_method = character(),
  notes = character()
)

readr::write_csv(cell_composition_plan, cell_comp_files$estimation_plan)
readr::write_csv(cell_composition_modeling_strategy, cell_comp_files$modeling_strategy)
readr::write_csv(cell_composition_template, cell_comp_files$cell_comp_template)

writeLines(
  c(
    "GSE42861 cell composition notes",
    "",
    "This script records the cell-composition handling plan only and does not estimate cell proportions yet.",
    "GSE42861 uses blood-derived samples, so cell mixture is a major interpretation issue for any future case-control EWAS result.",
    "Because the current first-pass route starts from metadata and a planned processed-matrix entry point, cell estimation is not yet ready to be run responsibly.",
    "The project should explicitly acknowledge this limitation in first-pass interpretation and add cell-adjusted sensitivity analyses later when the methylation object and estimation pathway are finalized."
  ),
  con = cell_comp_files$cell_comp_notes
)

print(cell_composition_plan)
print(cell_composition_modeling_strategy)

# Notes:
# - This step defines how cell composition will be handled conceptually.
# - No cell estimates are calculated here.
