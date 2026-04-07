# blood-dnam-disease-pipeline

Small, reproducible R portfolio project scaffold for an epigenome-wide association study (EWAS) using public blood DNA methylation case-control data, with rheumatoid arthritis as a likely first use case.

## Summary

This repository is designed as a student portfolio project rather than a dissertation-scale analysis. The goal is to build a clean, explainable workflow for working with public blood DNA methylation disease case-control data in R, with clear attention to quality control, confounding, and cautious interpretation.

## Project Motivation

This project is intended to show practical bioinformatics habits that translate well to research assistant, analyst, and junior computational biology roles. Instead of aiming for a large or highly novel study, it focuses on something easier to explain well: a disciplined, reproducible analysis of public blood methylation data using sensible workflow structure and restrained interpretation.

## Aims

- Organize a professional, GitHub-ready methylation analysis repo.
- Build a reproducible workflow for preprocessing, QC, modeling, annotation, and enrichment.
- Practice careful interpretation of blood-based disease-associated methylation patterns.
- Produce outputs that are realistic to discuss in interviews and portfolio reviews.

## Planned Workflow

1. Identify and document a suitable public blood DNA methylation case-control dataset.
2. Import raw or preprocessed methylation data and sample metadata.
3. Perform sample QC and basic exploratory checks.
4. Filter low-quality probes and apply an appropriate normalization strategy.
5. Estimate or incorporate blood cell-composition information where possible.
6. Build a design matrix with relevant covariates and confounder checks.
7. Run differential methylation analysis.
8. Annotate prioritized CpG sites or regions.
9. Perform cautious pathway enrichment and generate figures/tables.
10. Save session information and document reproducibility details.

## Proposed Dataset

The working target is a public blood DNA methylation case-control dataset relevant to rheumatoid arthritis or another well-documented disease phenotype. Final dataset selection has not yet been locked in, and this repository does not include downloaded data at this stage.

Selection criteria will include:

- Public accessibility
- Clear case-control definition
- Adequate sample metadata
- Blood-derived methylation measurements
- Reasonable size for a student portfolio project

The likely data source will be GEO or another well-documented public repository that provides either raw array files or a usable processed methylation matrix with sample annotations.

Notes on candidate datasets and final selection should be tracked in [docs/dataset_notes.md](/c:/Users/lukeo/OneDrive/VScode%20deposit/blood_dnam_ra_pipeline/docs/dataset_notes.md).

## Repository Structure

- `data/raw/`: local raw input files, excluded from version control
- `data/processed/`: processed intermediate data objects, excluded from version control
- `data/metadata/`: curated metadata templates and notes
- `results/qc/`: QC tables, plots, and summaries
- `results/differential_methylation/`: EWAS model outputs
- `results/annotation/`: CpG annotation tables
- `results/enrichment/`: pathway or gene set enrichment outputs
- `results/figures/`: final or draft visual outputs
- `scripts/`: ordered analysis scripts
- `functions/`: reusable helper functions
- `docs/`: project framing and interpretation notes
- `reports/`: rendered summaries, notebooks, or exportable reports

## Reproducibility

- Analysis code is organized into numbered scripts for a transparent execution order.
- Helper functions are separated from analysis scripts to keep the workflow modular.
- Large local data files are intentionally excluded from version control.
- Session information and package versions will be saved explicitly.
- The project will prefer scripted processing over manual spreadsheet edits.
- Dataset provenance, inclusion decisions, and interpretation notes will be documented alongside code.

## Interpretation Caution

This project is intentionally framed conservatively. Blood DNA methylation differences in disease case-control studies can reflect many processes beyond disease-specific biology, including:

- blood cell mixture differences
- inflammation
- age
- smoking
- medication or treatment exposure
- batch effects
- technical variation
- reverse causation

Any associations found in this project should be treated as hypothesis-generating rather than definitive evidence of disease mechanism. In particular, apparent disease signals in whole blood may reflect differences in immune cell abundance or inflammatory state rather than stable disease-specific epigenetic changes. The goal is to demonstrate good analytical habits, reproducibility, and scientific restraint.

## Status

This is an in-progress educational portfolio project. The repository currently contains scaffold code, project framing notes, and placeholders for a reproducible EWAS workflow. No dataset has been downloaded, no analysis has been run, and no results are reported yet.
