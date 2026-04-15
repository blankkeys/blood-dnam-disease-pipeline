# Script: 08_enrichment.R
# Purpose: Set up a cautious template for exploratory pathway or gene set enrichment analysis
# Expected inputs: Annotated prioritized CpGs or mapped genes from the annotation step
# Outputs: Enrichment planning tables and starter notes in results/enrichment

source(file.path("scripts", "00_setup.R"))
source(file.path("functions", "qc_helpers.R"))

enrichment_files <- list(
  enrichment_plan = file.path(paths$results_enrichment, "enrichment_plan.csv"),
  enrichment_dictionary = file.path(paths$results_enrichment, "enrichment_column_dictionary.csv"),
  enrichment_notes = file.path(paths$results_enrichment, "enrichment_notes.txt")
)

enrichment_plan <- tibble::tibble(
  decision_area = c(
    "input_feature_level",
    "gene_mapping_basis",
    "candidate_method",
    "background_definition",
    "reporting_style",
    "output_file"
  ),
  value = c(
    "annotated CpGs or mapped genes to be confirmed",
    "derived from annotation step and documented explicitly",
    "method to be confirmed after dataset and result structure are known",
    "array-aware background preferred where possible",
    "exploratory summary only",
    file.path("results", "enrichment", "enrichment_results.csv")
  )
)

enrichment_dictionary <- tibble::tibble(
  column_name = c(
    "term_id",
    "term_name",
    "gene_set_size",
    "overlap_size",
    "p_value",
    "adjusted_p_value",
    "method",
    "notes"
  ),
  intended_meaning = c(
    "Pathway or gene set identifier",
    "Human-readable pathway or term name",
    "Number of genes in the tested set",
    "Number of overlapping genes from the input list",
    "Nominal enrichment p-value",
    "Multiple-testing adjusted p-value",
    "Enrichment method used",
    "Short note about mapping or interpretation limits"
  )
)

write_csv_if_missing(enrichment_plan, enrichment_files$enrichment_plan)
write_csv_if_missing(enrichment_dictionary, enrichment_files$enrichment_dictionary)

if (!file.exists(enrichment_files$enrichment_notes)) {
  writeLines(
    c(
      "Enrichment notes",
      "",
      "Use this file to document gene mapping assumptions, background set choices, and reporting limits.",
      "Report enrichment as exploratory and sensitive to upstream filtering and annotation choices."
    ),
    con = enrichment_files$enrichment_notes
  )
}

print(enrichment_plan)

# TODO: Decide whether enrichment will be run on CpGs, mapped genes, or both.
# TODO: Choose a method appropriate for methylation-derived inputs and available annotation.
# TODO: Document the background set clearly before running enrichment.
# TODO: Keep enrichment outputs separate from stronger biological claims.
