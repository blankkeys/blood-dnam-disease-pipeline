# Script: 10_session_info_and_reproducibility.R
# Purpose: Save lightweight reproducibility records for the current analysis environment
# Expected inputs: A completed or partially completed analysis session
# Outputs: Session information, reproducibility checklist, and environment notes under reports

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

repro_files <- list(
  session_info = file.path(paths$reports, "session_info.txt"),
  reproducibility_checklist = file.path(paths$reports, "reproducibility_checklist.csv"),
  reproducibility_notes = file.path(paths$reports, "reproducibility_notes.txt")
)

reproducibility_checklist <- tibble::tibble(
  checklist_item = c(
    "Dataset accession recorded",
    "Raw or processed input source recorded",
    "Key preprocessing decisions documented",
    "Covariate and design choices documented",
    "Session information saved",
    "Output files stored in project structure",
    "Interpretation caveats documented"
  ),
  status = c(
    "pending",
    "pending",
    "pending",
    "pending",
    "complete",
    "pending",
    "complete"
  ),
  notes = ""
)

write_csv_if_missing(reproducibility_checklist, repro_files$reproducibility_checklist)

writeLines(capture.output(sessionInfo()), con = repro_files$session_info)

if (!file.exists(repro_files$reproducibility_notes)) {
  writeLines(
    c(
      "Reproducibility notes",
      "",
      paste("Run timestamp:", format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")),
      paste("Project root:", project_root),
      "",
      "Use this file to record important environment details, manual decisions, and any steps that could affect reproducibility."
    ),
    con = repro_files$reproducibility_notes
  )
}

message("Wrote session information to: ", repro_files$session_info)
message("Reproducibility checklist available at: ", repro_files$reproducibility_checklist)

# TODO: Consider switching to sessioninfo::session_info() once package choices are finalized.
# TODO: Update checklist statuses as real dataset and analysis decisions are completed.
