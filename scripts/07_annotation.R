# Script: 07_annotation.R
# Purpose: Define a cautious starter workflow for annotating prioritized CpG results
# Expected inputs: Differential methylation result tables and platform-specific annotation resources
# Outputs: Annotation planning files and starter table templates in results/annotation

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

annotation_files <- list(
  annotation_plan = file.path(paths$results_annotation, "annotation_plan.csv"),
  annotation_dictionary = file.path(paths$results_annotation, "annotation_column_dictionary.csv"),
  annotation_notes = file.path(paths$results_annotation, "annotation_notes.txt")
)

annotation_plan <- tibble::tibble(
  decision_area = c(
    "array_platform",
    "annotation_source",
    "input_result_file",
    "probe_to_gene_mapping_strategy",
    "genomic_context_fields",
    "annotated_output_file"
  ),
  value = c(
    NA_character_,
    NA_character_,
    file.path("results", "differential_methylation", "complete_results.csv"),
    "platform annotation package to be confirmed",
    "CpG island context; gene symbol; chromosome; genomic position",
    file.path("results", "annotation", "annotated_differential_methylation_results.csv")
  )
)

annotation_dictionary <- tibble::tibble(
  column_name = c(
    "probe_id",
    "chromosome",
    "position",
    "gene_symbol",
    "feature_context",
    "cpg_island_relation",
    "annotation_source"
  ),
  intended_meaning = c(
    "CpG probe identifier",
    "Chromosome label from the chosen annotation source",
    "Genomic coordinate from the chosen annotation source",
    "Mapped gene symbol or symbols if available",
    "Gene feature context such as promoter or gene body",
    "Relation to CpG island, shore, shelf, or open sea",
    "Package or table used for annotation"
  )
)

write_csv_if_missing(annotation_plan, annotation_files$annotation_plan)
write_csv_if_missing(annotation_dictionary, annotation_files$annotation_dictionary)

if (!file.exists(annotation_files$annotation_notes)) {
  writeLines(
    c(
      "Annotation notes",
      "",
      "Use this file to document which platform annotation resource was used and any probe-to-gene mapping limitations.",
      "Keep raw statistical outputs separate from annotated summary tables."
    ),
    con = annotation_files$annotation_notes
  )
}

print(annotation_plan)

# TODO: Confirm the final array platform and matching annotation package.
# TODO: Load the complete differential methylation result table once modeling outputs exist.
# TODO: Merge platform annotation fields onto the full results without overwriting raw statistics.
# TODO: Save annotated full results separately from smaller interpreted summaries.
