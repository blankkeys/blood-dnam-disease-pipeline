# Script: 00_setup.R
# Purpose: Define basic project paths, likely package requirements, and helper setup
# Expected inputs: None; run from the project root in a fresh R session
# Outputs: Package vectors, directory checks, and starter setup objects in memory

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

cran_packages <- c(
  "tidyverse",
  "janitor",
  "here",
  "fs",
  "glue",
  "sessioninfo"
)

bioc_packages <- c(
  "GEOquery",
  "minfi",
  "limma",
  "missMethyl",
  "IlluminaHumanMethylation450kanno.ilmn12.hg19",
  "IlluminaHumanMethylationEPICanno.ilm10b4.hg19"
)

# TODO: Confirm the final dataset and platform before narrowing the package set.
# TODO: Decide whether package management will use renv, pak, or manual installation.
# TODO: Add project-specific options once the workflow is defined.

message("Project root: ", project_root)
