# Script: 10_session_info_and_reproducibility.R
# Purpose: Save session information and reproducibility details for the project
# Expected inputs: A completed or partially completed analysis session
# Outputs: Session info text file and reproducibility notes under reports or results

output_file <- file.path("reports", "session_info.txt")

# TODO: Consider switching to sessioninfo::session_info() once packages are finalized.
writeLines(capture.output(sessionInfo()), con = output_file)

message("Wrote session information to: ", output_file)
