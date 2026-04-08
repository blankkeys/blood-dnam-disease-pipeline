# Script: 00_setup.R
# Purpose: Define project paths, likely package requirements, and safe setup helpers
# Expected inputs: None; run from the project root in a fresh R session
# Outputs: Directory checks, package lists, helper objects, and basic session metadata

project_root <- normalizePath(".", winslash = "/", mustWork = TRUE)

dir_paths <- c(
  "data/raw",
  "data/processed",
  "data/metadata",
  "results/qc",
  "results/differential_methylation",
  "results/annotation",
  "results/enrichment",
  "results/figures",
  "reports"
)

invisible(lapply(dir_paths, dir.create, recursive = TRUE, showWarnings = FALSE))

paths <- list(
  project_root = project_root,
  data_raw = file.path(project_root, "data", "raw"),
  data_processed = file.path(project_root, "data", "processed"),
  data_metadata = file.path(project_root, "data", "metadata"),
  results_qc = file.path(project_root, "results", "qc"),
  results_dm = file.path(project_root, "results", "differential_methylation"),
  results_annotation = file.path(project_root, "results", "annotation"),
  results_enrichment = file.path(project_root, "results", "enrichment"),
  results_figures = file.path(project_root, "results", "figures"),
  reports = file.path(project_root, "reports")
)

cran_packages <- c(
  "readr",
  "dplyr",
  "tibble",
  "stringr",
  "ggplot2",
  "janitor",
  "here",
  "fs",
  "glue",
  "sessioninfo"
)

bioc_packages <- c(
  "BiocManager",
  "GEOquery",
  "minfi",
  "limma",
  "missMethyl",
  "IlluminaHumanMethylation450kanno.ilmn12.hg19",
  "IlluminaHumanMethylationEPICanno.ilm10b4.hg19"
)

all_packages <- unique(c(cran_packages, bioc_packages))

is_installed <- function(pkg) {
  requireNamespace(pkg, quietly = TRUE)
}

check_required_packages <- function(pkg_vector) {
  pkg_vector[!vapply(pkg_vector, is_installed, logical(1))]
}

install_missing_packages <- function(
  cran_pkgs = cran_packages,
  bioc_pkgs = bioc_packages,
  install = FALSE
) {
  missing_cran <- check_required_packages(cran_pkgs)
  missing_bioc <- setdiff(check_required_packages(bioc_pkgs), "BiocManager")

  if (!install) {
    return(list(
      missing_cran = missing_cran,
      missing_bioc = missing_bioc
    ))
  }

  if (length(missing_cran) > 0) {
    install.packages(missing_cran)
  }

  if (!is_installed("BiocManager")) {
    install.packages("BiocManager")
  }

  if (length(missing_bioc) > 0) {
    BiocManager::install(missing_bioc, ask = FALSE, update = FALSE)
  }

  invisible(list(
    missing_cran = missing_cran,
    missing_bioc = missing_bioc
  ))
}

session_metadata <- list(
  run_timestamp = format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z"),
  r_version = R.version.string,
  platform = R.version$platform,
  working_directory = getwd()
)

missing_packages <- install_missing_packages(install = FALSE)

message("Project root: ", project_root)
message("Directories checked: ", length(dir_paths))
message("Missing CRAN packages: ", length(missing_packages$missing_cran))
message("Missing Bioconductor packages: ", length(missing_packages$missing_bioc))

# TODO: Confirm the final dataset and platform before narrowing the package set.
# TODO: Decide whether package management will use renv, pak, or manual installation.
# TODO: Source reusable helpers once helper functions become project-specific.
