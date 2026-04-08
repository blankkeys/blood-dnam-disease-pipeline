# Script: 01_download_or_import_data.R
# Purpose: Set up a documented import plan for public methylation data without downloading it yet
# Expected inputs: A confirmed GEO accession or local data source, plus metadata decisions
# Outputs: Metadata templates and a clear import configuration object for later use

source(file.path("scripts", "00_setup.R"))

dataset_config <- list(
  project_name = "blood-dnam-disease-pipeline",
  source_type = "GEO",
  accession = NA_character_,
  disease_focus = "To be confirmed",
  sample_source = "Whole blood or peripheral blood",
  preferred_input = "raw_idat_if_available",
  fallback_input = "processed_matrix",
  notes = c(
    "Do not download data until dataset selection is documented.",
    "Prefer datasets with usable phenotype metadata and clear case-control labels.",
    "Record whether raw IDAT files or only processed matrices are available."
  )
)

planned_outputs <- list(
  metadata_template = file.path(paths$data_metadata, "sample_metadata_template.csv"),
  import_log_template = file.path(paths$data_metadata, "import_log_template.csv"),
  dataset_config_rds = file.path(paths$data_metadata, "dataset_config.rds")
)

metadata_template <- tibble::tibble(
  sample_id = character(),
  sample_label = character(),
  group = character(),
  age = numeric(),
  sex = character(),
  smoking_status = character(),
  treatment_status = character(),
  batch = character(),
  source_file = character(),
  inclusion_flag = logical(),
  notes = character()
)

import_log_template <- tibble::tibble(
  import_date = character(),
  accession = character(),
  source_type = character(),
  file_name = character(),
  file_type = character(),
  destination = character(),
  download_performed = logical(),
  checksum_recorded = logical(),
  notes = character()
)

if (!file.exists(planned_outputs$metadata_template)) {
  readr::write_csv(metadata_template, planned_outputs$metadata_template)
}

if (!file.exists(planned_outputs$import_log_template)) {
  readr::write_csv(import_log_template, planned_outputs$import_log_template)
}

saveRDS(dataset_config, planned_outputs$dataset_config_rds)

message("Prepared dataset import templates in: ", paths$data_metadata)

# TODO: Replace NA accession with the selected GEO series once the dataset is chosen.
# TODO: Add GEOquery-based import code only after the dataset and preferred input format are confirmed.
# TODO: Record source URLs, file provenance, and any manual metadata transformations explicitly.
