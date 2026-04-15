# Script: 01_download_or_import_data.R
# Purpose: Retrieve and parse sample metadata, then register the processed methylation matrix for the selected GEO dataset
# Expected inputs: Internet access, the selected GEO accession, and the project scaffold
# Outputs: Raw and cleaned sample metadata tables plus processed-matrix registration summaries in data/metadata and results/qc

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
  metadata_source_type = "series_matrix_header",
  processed_matrix_filename = "GSE42861_processed_methylation_matrix.txt.gz",
  notes = c(
    "This step retrieves and parses sample metadata only.",
    "It does not run downstream analysis.",
    "Parsed variables should be treated as candidate review fields until checked manually."
  )
)

metadata_url <- paste0(
  "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE42nnn/",
  dataset_config$accession,
  "/matrix/",
  dataset_config$accession,
  "_series_matrix.txt.gz"
)

processed_matrix_url <- paste0(
  "https://ftp.ncbi.nlm.nih.gov/geo/series/GSE42nnn/",
  dataset_config$accession,
  "/suppl/",
  dataset_config$processed_matrix_filename
)

planned_outputs <- list(
  metadata_archive = file.path(
    paths$data_metadata,
    paste0(dataset_config$accession, "_series_matrix.txt.gz")
  ),
  raw_metadata = file.path(
    paths$data_metadata,
    paste0(dataset_config$accession, "_samples_raw.csv")
  ),
  cleaned_metadata = file.path(
    paths$data_metadata,
    paste0(dataset_config$accession, "_samples_cleaned.csv")
  ),
  reviewed_metadata = file.path(
    paths$data_metadata,
    paste0(dataset_config$accession, "_samples_reviewed.csv")
  ),
  analysis_cohort_metadata = file.path(
    paths$data_metadata,
    paste0(dataset_config$accession, "_analysis_cohort.csv")
  ),
  field_summary = file.path(
    paths$results_qc,
    paste0(dataset_config$accession, "_metadata_field_summary.csv")
  ),
  missingness_summary = file.path(
    paths$results_qc,
    paste0(dataset_config$accession, "_metadata_missingness_summary.csv")
  ),
  value_summary = file.path(
    paths$results_qc,
    paste0(dataset_config$accession, "_metadata_value_summary.csv")
  ),
  cohort_summary = file.path(
    paths$results_qc,
    paste0(dataset_config$accession, "_analysis_cohort_summary.csv")
  ),
  processed_matrix_archive = file.path(
    paths$data_raw,
    dataset_config$processed_matrix_filename
  ),
  processed_matrix_manifest = file.path(
    paths$data_metadata,
    paste0(dataset_config$accession, "_processed_matrix_manifest.csv")
  ),
  processed_matrix_column_summary = file.path(
    paths$results_qc,
    paste0(dataset_config$accession, "_processed_matrix_column_summary.csv")
  ),
  processed_matrix_sample_map = file.path(
    paths$data_metadata,
    paste0(dataset_config$accession, "_processed_matrix_sample_map.csv")
  )
)

download_gz_if_missing <- function(url, destfile, object_label) {
  if (file.exists(destfile)) {
    message("Using existing ", object_label, ": ", destfile)
    return(invisible(destfile))
  }

  message("Downloading GEO ", object_label, ": ", basename(destfile))

  tryCatch(
    {
      utils::download.file(url = url, destfile = destfile, mode = "wb", quiet = FALSE)
    },
    error = function(e) {
      stop(
        "Failed to retrieve GEO metadata archive from ", url, ". ",
        "Check network access and GEO availability. Original error: ", conditionMessage(e),
        call. = FALSE
      )
    }
  )

  invisible(destfile)
read_series_matrix_header_lines <- function(gz_path) {
  con <- gzfile(gz_path, open = "rt")
  on.exit(close(con), add = TRUE)

  header_lines <- character()

  repeat {
    line <- readLines(con, n = 1)

    if (length(line) == 0) {
      break
    }

    if (identical(line, "!series_matrix_table_begin")) {
      break
    }

    header_lines <- c(header_lines, line)
  }

  header_lines
}

read_first_gz_line <- function(gz_path) {
  con <- gzfile(gz_path, open = "rt")
  on.exit(close(con), add = TRUE)
  readLines(con, n = 1)
}

strip_geo_quotes <- function(x) {
  x <- gsub('^"', "", x)
  x <- gsub('"$', "", x)
  x
}

parse_sample_metadata_from_header <- function(header_lines) {
  sample_lines <- header_lines[grepl("^!Sample_", header_lines)]

  if (length(sample_lines) == 0) {
    stop("No !Sample_ metadata lines were found in the GEO series-matrix header.", call. = FALSE)
  }

  parsed_lines <- lapply(sample_lines, function(line) {
    parts <- strsplit(line, "\t", fixed = TRUE)[[1]]
    field_name <- sub("^!Sample_", "", parts[1])
    values <- strip_geo_quotes(parts[-1])

    list(field_name = field_name, values = values)
  })

  field_names <- vapply(parsed_lines, `[[`, character(1), "field_name")
  unique_field_names <- make.unique(field_names, sep = "_")
  value_lengths <- vapply(parsed_lines, function(x) length(x$values), integer(1))

  if (length(unique(value_lengths)) != 1) {
    stop("Sample metadata fields do not all contain the same number of samples.", call. = FALSE)
  }

  raw_metadata <- tibble::as_tibble(
    as.data.frame(
      setNames(
        lapply(parsed_lines, `[[`, "values"),
        unique_field_names
      ),
      stringsAsFactors = FALSE,
      check.names = FALSE
    )
  )

  raw_metadata
}

parse_characteristic_column <- function(x) {
  non_missing <- x[!is.na(x) & nzchar(x)]

  if (length(non_missing) == 0) {
    return(NULL)
  }

  matches <- regexec("^([^:]+):\\s*(.*)$", non_missing)
  captures <- regmatches(non_missing, matches)
  valid <- vapply(captures, length, integer(1)) == 3L

  if (!all(valid)) {
    return(NULL)
  }

  keys <- unique(trimws(vapply(captures, `[`, character(1), 2)))

  if (length(keys) != 1) {
    return(NULL)
  }

  full_matches <- regmatches(x, regexec("^([^:]+):\\s*(.*)$", x))
  values <- vapply(
    full_matches,
    function(match) {
      if (length(match) == 3L) {
        trimws(match[3])
      } else {
        NA_character_
      }
    },
    character(1)
  )

  parsed_name <- janitor::make_clean_names(keys)

  list(
    parsed_name = parsed_name,
    parsed_values = values,
    source_key = keys
  )
}

clean_gse42861_metadata <- function(raw_metadata) {
  cleaned <- dplyr::transmute(
    raw_metadata,
    sample_id = geo_accession,
    sample_label = title,
    source_name = source_name_ch1,
    platform_id = platform_id
  )

  characteristic_columns <- grep("^characteristics_ch1", names(raw_metadata), value = TRUE)
  parsed_characteristics <- lapply(characteristic_columns, function(col_name) {
    parsed <- parse_characteristic_column(raw_metadata[[col_name]])

    if (is.null(parsed)) {
      return(NULL)
    }

    parsed$source_column <- col_name
    parsed
  })

  parsed_characteristics <- parsed_characteristics[!vapply(parsed_characteristics, is.null, logical(1))]

  if (length(parsed_characteristics) > 0) {
    parsed_names <- make.unique(
      vapply(parsed_characteristics, `[[`, character(1), "parsed_name"),
      sep = "_"
    )

    for (i in seq_along(parsed_characteristics)) {
      cleaned[[parsed_names[i]]] <- parsed_characteristics[[i]]$parsed_values
    }
  }

  cleaned$sample_number_from_title <- suppressWarnings(
    as.integer(stringr::str_extract(cleaned$sample_label, "(?<=sample )\\d+"))
  )

  if ("subject" %in% names(cleaned)) {
    cleaned$candidate_case_control_status <- dplyr::case_when(
      cleaned$subject == "Patient" ~ "case",
      cleaned$subject == "Normal" ~ "control",
      TRUE ~ NA_character_
    )
  }

  if ("age" %in% names(cleaned)) {
    cleaned$age <- suppressWarnings(as.integer(cleaned$age))
  }

  raw_characteristic_cols <- raw_metadata[, characteristic_columns, drop = FALSE]

  dplyr::bind_cols(
    cleaned,
    raw_characteristic_cols
  )
}

review_gse42861_metadata <- function(cleaned_metadata) {
  reviewed <- cleaned_metadata

  if ("subject" %in% names(reviewed)) {
    reviewed$subject_reviewed <- dplyr::case_when(
      reviewed$subject == "Patient" ~ "patient",
      reviewed$subject == "Normal" ~ "control_source_label",
      TRUE ~ NA_character_
    )
  }

  if ("disease_state" %in% names(reviewed)) {
    reviewed$disease_state_reviewed <- dplyr::case_when(
      reviewed$disease_state == "rheumatoid arthritis" ~ "rheumatoid_arthritis",
      reviewed$disease_state == "Normal" ~ "normal",
      TRUE ~ NA_character_
    )
  }

  if ("gender" %in% names(reviewed)) {
    reviewed$sex_reviewed <- dplyr::case_when(
      reviewed$gender == "f" ~ "female",
      reviewed$gender == "m" ~ "male",
      TRUE ~ NA_character_
    )
  }

  if ("smoking_status" %in% names(reviewed)) {
    reviewed$smoking_status_reviewed <- dplyr::case_when(
      reviewed$smoking_status == "current" ~ "current",
      reviewed$smoking_status == "ex" ~ "former",
      reviewed$smoking_status == "never" ~ "never",
      reviewed$smoking_status == "occasional" ~ "occasional",
      reviewed$smoking_status == "na" ~ NA_character_,
      TRUE ~ NA_character_
    )
  }

  if ("candidate_case_control_status" %in% names(reviewed)) {
    reviewed$case_control_status_reviewed <- reviewed$candidate_case_control_status
  }

  reviewed
}

summarise_metadata_fields <- function(tbl, table_name) {
  tibble::tibble(
    table_name = table_name,
    field_name = names(tbl),
    non_missing_n = vapply(
      tbl,
      function(x) sum(!is.na(x) & nzchar(as.character(x))),
      integer(1)
    ),
    missing_n = vapply(
      tbl,
      function(x) sum(is.na(x) | !nzchar(as.character(x))),
      integer(1)
    ),
    unique_non_missing_n = vapply(
      tbl,
      function(x) dplyr::n_distinct(x[!is.na(x) & nzchar(as.character(x))]),
      integer(1)
    ),
    example_values = vapply(
      tbl,
      function(x) {
        vals <- unique(as.character(x[!is.na(x) & nzchar(as.character(x))]))
        vals <- vals[seq_len(min(length(vals), 3))]
        paste(vals, collapse = " | ")
      },
      character(1)
    )
  )
}

build_candidate_covariate_missingness <- function(cleaned_metadata) {
  candidate_fields <- intersect(
    c(
      "disease_state",
      "subject",
      "candidate_case_control_status",
      "age",
      "gender",
      "smoking_status",
      "cell_type",
      "source_name",
      "platform_id"
    ),
    names(cleaned_metadata)
  )

  tibble::tibble(
    field_name = candidate_fields,
    non_missing_n = vapply(
      cleaned_metadata[candidate_fields],
      function(x) sum(!is.na(x) & nzchar(as.character(x))),
      integer(1)
    ),
    missing_n = vapply(
      cleaned_metadata[candidate_fields],
      function(x) sum(is.na(x) | !nzchar(as.character(x))),
      integer(1)
    ),
    unique_non_missing_n = vapply(
      cleaned_metadata[candidate_fields],
      function(x) dplyr::n_distinct(x[!is.na(x) & nzchar(as.character(x))]),
      integer(1)
    )
  )
}

build_value_summary <- function(reviewed_metadata) {
  fields_to_review <- intersect(
    c(
      "subject",
      "subject_reviewed",
      "disease_state",
      "disease_state_reviewed",
      "gender",
      "sex_reviewed",
      "smoking_status",
      "smoking_status_reviewed",
      "candidate_case_control_status",
      "case_control_status_reviewed"
    ),
    names(reviewed_metadata)
  )

  dplyr::bind_rows(
    lapply(fields_to_review, function(field_name) {
      reviewed_metadata |>
        dplyr::count(.data[[field_name]], name = "n", .drop = FALSE) |>
        dplyr::rename(value = .data[[field_name]]) |>
        dplyr::mutate(field_name = field_name, .before = 1)
    })
  )
}

select_first_pass_analysis_cohort <- function(reviewed_metadata) {
  reviewed_metadata |>
    dplyr::mutate(
      include_first_pass = dplyr::case_when(
        is.na(case_control_status_reviewed) ~ FALSE,
        TRUE ~ TRUE
      ),
      first_pass_exclusion_reason = dplyr::case_when(
        is.na(case_control_status_reviewed) ~ "missing_case_control_status",
        TRUE ~ NA_character_
      ),
      smoking_missing_flag = is.na(smoking_status_reviewed),
      age_missing_flag = is.na(age),
      sex_missing_flag = is.na(sex_reviewed),
      first_pass_cohort_note = dplyr::case_when(
        include_first_pass & smoking_missing_flag ~ "included_but_missing_smoking_status",
        include_first_pass ~ "included_in_initial_case_control_cohort",
        TRUE ~ "excluded_from_initial_case_control_cohort"
      )
    )
}

build_cohort_summary <- function(cohort_metadata) {
  dplyr::bind_rows(
    cohort_metadata |>
      dplyr::count(
        summary_type = "include_first_pass",
        summary_value = ifelse(include_first_pass, "included", "excluded"),
        name = "n"
      ),
    cohort_metadata |>
      dplyr::count(
        summary_type = "case_control_status_reviewed",
        summary_value = case_control_status_reviewed,
        name = "n"
      ),
    cohort_metadata |>
      dplyr::count(
        summary_type = "smoking_missing_flag",
        summary_value = ifelse(smoking_missing_flag, "missing", "present"),
        name = "n"
      ),
    cohort_metadata |>
      dplyr::count(
        summary_type = "first_pass_cohort_note",
        summary_value = first_pass_cohort_note,
        name = "n"
      )
  )
}

extract_array_position_id <- function(supplementary_file) {
  stringr::str_match(
    supplementary_file,
    "GSM\\d+_([^_]+_R\\d{2}C\\d{2})_(?:Grn|Red)\\.idat\\.gz$"
  )[, 2]
}

build_processed_matrix_manifest <- function(processed_matrix_header, raw_metadata) {
  header_fields <- strsplit(processed_matrix_header, "\t", fixed = TRUE)[[1]]

  processed_matrix_columns <- tibble::tibble(
    column_name = header_fields,
    column_type = dplyr::case_when(
      header_fields == "ID_REF" ~ "probe_id",
      header_fields == "Pval" ~ "p_value_summary",
      TRUE ~ "sample_signal"
    )
  )

  sample_columns <- processed_matrix_columns |>
    dplyr::filter(column_type == "sample_signal") |>
    dplyr::pull(column_name)

  sample_map <- raw_metadata |>
    dplyr::transmute(
      sample_id = geo_accession,
      sample_label = title,
      source_name = source_name_ch1,
      supplementary_file,
      array_position_id = extract_array_position_id(supplementary_file)
    ) |>
    dplyr::mutate(
      present_in_processed_matrix = array_position_id %in% sample_columns
    )

  manifest <- tibble::tibble(
    decision_area = c(
      "dataset_accession",
      "processed_matrix_file",
      "row_id_column",
      "sample_column_count",
      "special_trailing_column",
      "mapped_sample_count",
      "unmapped_sample_count"
    ),
    value = c(
      dataset_config$accession,
      basename(planned_outputs$processed_matrix_archive),
      "ID_REF",
      as.character(length(sample_columns)),
      ifelse("Pval" %in% header_fields, "Pval", "none_detected"),
      as.character(sum(sample_map$present_in_processed_matrix, na.rm = TRUE)),
      as.character(sum(!sample_map$present_in_processed_matrix, na.rm = TRUE))
    )
  )

  list(
    manifest = manifest,
    column_summary = processed_matrix_columns,
    sample_map = sample_map
  )
}

download_gz_if_missing(metadata_url, planned_outputs$metadata_archive, "metadata archive")

header_lines <- read_series_matrix_header_lines(planned_outputs$metadata_archive)
raw_sample_metadata <- parse_sample_metadata_from_header(header_lines)

if (nrow(raw_sample_metadata) != dataset_config$geo_sample_count) {
  stop(
    "Retrieved ", nrow(raw_sample_metadata), " samples, but expected ",
    dataset_config$geo_sample_count, " for ", dataset_config$accession, ".",
    call. = FALSE
  )
}

cleaned_sample_metadata <- clean_gse42861_metadata(raw_sample_metadata)
reviewed_sample_metadata <- review_gse42861_metadata(cleaned_sample_metadata)
analysis_cohort_metadata <- select_first_pass_analysis_cohort(reviewed_sample_metadata)

field_summary <- dplyr::bind_rows(
  summarise_metadata_fields(raw_sample_metadata, "raw"),
  summarise_metadata_fields(cleaned_sample_metadata, "cleaned"),
  summarise_metadata_fields(reviewed_sample_metadata, "reviewed"),
  summarise_metadata_fields(analysis_cohort_metadata, "analysis_cohort")
)

missingness_summary <- build_candidate_covariate_missingness(analysis_cohort_metadata)
value_summary <- build_value_summary(analysis_cohort_metadata)
cohort_summary <- build_cohort_summary(analysis_cohort_metadata)

download_gz_if_missing(
  processed_matrix_url,
  planned_outputs$processed_matrix_archive,
  "processed methylation matrix"
)

processed_matrix_header <- read_first_gz_line(planned_outputs$processed_matrix_archive)
processed_matrix_registration <- build_processed_matrix_manifest(
  processed_matrix_header = processed_matrix_header,
  raw_metadata = raw_sample_metadata
)

readr::write_csv(raw_sample_metadata, planned_outputs$raw_metadata)
readr::write_csv(cleaned_sample_metadata, planned_outputs$cleaned_metadata)
readr::write_csv(reviewed_sample_metadata, planned_outputs$reviewed_metadata)
readr::write_csv(analysis_cohort_metadata, planned_outputs$analysis_cohort_metadata)
readr::write_csv(field_summary, planned_outputs$field_summary)
readr::write_csv(missingness_summary, planned_outputs$missingness_summary)
readr::write_csv(value_summary, planned_outputs$value_summary)
readr::write_csv(cohort_summary, planned_outputs$cohort_summary)
readr::write_csv(
  processed_matrix_registration$manifest,
  planned_outputs$processed_matrix_manifest
)
readr::write_csv(
  processed_matrix_registration$column_summary,
  planned_outputs$processed_matrix_column_summary
)
readr::write_csv(
  processed_matrix_registration$sample_map,
  planned_outputs$processed_matrix_sample_map
)

message("Saved raw sample metadata to: ", planned_outputs$raw_metadata)
message("Saved cleaned sample metadata to: ", planned_outputs$cleaned_metadata)
message("Saved reviewed sample metadata to: ", planned_outputs$reviewed_metadata)
message("Saved analysis cohort metadata to: ", planned_outputs$analysis_cohort_metadata)
message("Saved metadata field summary to: ", planned_outputs$field_summary)
message("Saved metadata missingness summary to: ", planned_outputs$missingness_summary)
message("Saved metadata value summary to: ", planned_outputs$value_summary)
message("Saved cohort summary to: ", planned_outputs$cohort_summary)
message("Saved processed matrix manifest to: ", planned_outputs$processed_matrix_manifest)
message("Saved processed matrix column summary to: ", planned_outputs$processed_matrix_column_summary)
message("Saved processed matrix sample map to: ", planned_outputs$processed_matrix_sample_map)

# Notes:
# - This step prepares metadata and registers the processed methylation matrix only.
# - Parsed fields are candidate review variables, not automatically validated covariates.
# - Variables such as treatment, severity, and technical batch should be treated as absent unless
#   they are confirmed in the retrieved GEO metadata.
