# Script: 01_download_or_import_data.R
# Purpose: Set up a documented import plan for the selected GEO methylation dataset without downloading it yet
# Expected inputs: A confirmed GEO accession and metadata decisions for the first-pass portfolio workflow
# Outputs: Metadata templates, a GEO-specific import configuration object, and starter field-mapping notes

source(file.path("scripts", "00_setup.R"))

dataset_config <- list(
  project_name = "blood-dnam-disease-pipeline",
  source_type = "GEO",
  accession = "GSE42861",
  dataset_title = "Differential DNA methylation in Rheumatoid arthritis",
  disease_focus = "Rheumatoid arthritis",
  sample_source = "Peripheral blood leukocytes",
  organism = "Homo sapiens",
  platform = "GPL13534",
  array = "Illumina HumanMethylation450 BeadChip",
  geo_sample_count = 689L,
  preferred_input = "raw_idat_if_available",
  fallback_input = "processed_matrix",
  expected_geo_fields = c(
    "geo_accession",
    "title",
    "source_name_ch1",
    "characteristics_ch1"
  ),
  candidate_metadata_variables = c(
    "case_control_status",
    "age",
    "sex",
    "smoking_status",
    "batch_or_array_position",
    "serology_or_subtype_labels"
  ),
  notes = c(
    "GEO series page reports both raw IDAT availability and processed methylation tables.",
    "Phenotype definitions and covariates must still be verified directly from GEO sample metadata.",
    "Do not download data until the metadata extraction plan is reviewed."
  )
)

planned_outputs <- list(
  metadata_template = file.path(paths$data_metadata, "sample_metadata_template.csv"),
  import_log_template = file.path(paths$data_metadata, "import_log_template.csv"),
  dataset_config_rds = file.path(paths$data_metadata, "dataset_config.rds"),
  geo_field_map = file.path(paths$data_metadata, "geo_field_map.csv"),
  import_strategy_notes = file.path(paths$data_metadata, "import_strategy_notes.txt")
)

geo_field_map <- tibble::tibble(
  geo_field = c(
    "geo_accession",
    "title",
    "source_name_ch1",
    "characteristics_ch1",
    "supplementary_file"
  ),
  planned_project_field = c(
    "sample_id",
    "sample_label",
    "sample_source",
    "metadata_key_value_pairs",
    "raw_or_processed_source_file"
  ),
  notes = c(
    "Expected GSM sample accession",
    "Short sample label from GEO sample record",
    "Useful for confirming peripheral blood leukocyte source",
    "Likely contains phenotype and covariate fields to parse carefully",
    "Use to record IDAT or processed file provenance when import begins"
  )
)

geoquery_import_plan <- list(
  series_function = "GEOquery::getGEO('GSE42861', GSEMatrix = TRUE)",
  sample_metadata_source = "pData on returned ExpressionSet object or parsed GEO sample records",
  raw_data_check = "Confirm supplementary files and raw IDAT archive before deciding import path",
  first_pass_goal = "Inspect metadata structure only; do not download full raw data yet"
)

metadata_template <- tibble::tibble(
  sample_id = character(),
  sample_label = character(),
  geo_accession = character(),
  group = character(),
  source_name = character(),
  age = numeric(),
  sex = character(),
  smoking_status = character(),
  treatment_status = character(),
  batch = character(),
  serology_subtype = character(),
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

if (!file.exists(planned_outputs$geo_field_map)) {
  readr::write_csv(geo_field_map, planned_outputs$geo_field_map)
}

saveRDS(dataset_config, planned_outputs$dataset_config_rds)

if (!file.exists(planned_outputs$import_strategy_notes)) {
  writeLines(
    c(
      "Import strategy notes",
      "",
      "Selected GEO accession: GSE42861",
      "Planned first-pass import route: inspect series and sample metadata with GEOquery before choosing raw IDAT or processed-matrix entry point.",
      "Expected metadata fields to inspect: source_name_ch1 and characteristics_ch1.",
      "Expected phenotype variables to verify: case/control status, age, sex, smoking, and any serology subgroup labels.",
      "Do not download the raw archive until metadata structure and project scope are confirmed."
    ),
    con = planned_outputs$import_strategy_notes
  )
}

message("Prepared dataset import templates in: ", paths$data_metadata)
message("Selected GEO accession: ", dataset_config$accession)

# TODO: Add metadata-inspection code using the planned GEOquery route once we are ready to inspect live sample records.
# TODO: Replace generic group labels with verified case/control definitions from GEO metadata.
# TODO: Decide whether the first real import should begin from the processed matrix or the raw IDAT archive.
# TODO: Record source URLs, file provenance, and any manual metadata transformations explicitly.
