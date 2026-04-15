# Dataset Notes

## Purpose

This document is for tracking candidate public datasets, inclusion criteria, accession IDs, platform details, and any important metadata limitations.

## Current Leading Candidate

- GEO accession: `GSE42861`
- Title: `Differential DNA methylation in Rheumatoid arthritis`
- Disease: rheumatoid arthritis
- Tissue/source: peripheral blood leukocytes (PBLs)
- Platform: `GPL13534`, Illumina HumanMethylation450 BeadChip
- GEO sample count: 689 samples total
- Case/control structure:
  - GEO labels samples as patient or normal genomic DNA.
  - A later secondary analysis describes this dataset as 354 ACPA-associated RA cases and 335 controls.
  - This exact phenotype definition should still be verified directly from GEO sample metadata before modeling.
- Metadata or covariates to inspect:
  - case and control labels
  - age
  - sex
  - smoking status
  - any batch or array-position variables
  - any disease-subtype or serology labels such as ACPA status
- Raw data availability:
  - GEO lists `GSE42861_RAW.tar` as a 5.7 GB archive of IDAT files.
- Processed data availability:
  - GEO lists a processed methylation matrix and signal matrices.
  - Processed data are also included within the sample table according to the GEO record.
- Why this is a good fit:
  - blood-derived case-control methylation data
  - established 450K platform with standard Bioconductor support
  - large enough to be realistic and interesting for a portfolio project
  - both raw and processed starting points appear to be available
- Likely analysis caveats:
  - whole-blood/peripheral blood leukocyte methylation is highly sensitive to cell-composition differences
  - RA case-control differences may reflect inflammation, smoking, medication, or serology subgroup structure
  - the total dataset is large enough that a portfolio project may need a deliberately modest first-pass scope
  - phenotype definition and available covariates must be checked carefully before deciding on the main contrast
- Provisional decision:
  - `GSE42861` is currently the best documented first-choice dataset for this repository, but final adoption should wait until the sample metadata are inspected directly.

## Verification Checklist For GSE42861

- Confirm whether the main comparison should use all RA cases versus controls, or a narrower subset.
- Verify whether age, sex, and smoking are present in the GEO sample metadata or only in linked publications.
- Check whether raw IDAT import is feasible within project scope, or whether the first pass should begin from the processed matrix.
- Confirm whether any duplicated samples, technical replicates, or subgroup structures need to be excluded.
- Decide whether the first portfolio analysis should use the full cohort or a simpler, well-documented subset.

## Candidate Dataset Checklist

- Accession or source:
- Disease or phenotype:
- Tissue/source:
- Platform:
- Sample size:
- Case definition:
- Control definition:
- Available covariates:
- Raw IDAT files available:
- Processed matrix available:
- Key exclusion concerns:

## Selection Principles

- Prefer blood-derived methylation data with clear case-control labels.
- Prefer datasets with usable metadata for age, sex, smoking, treatment, or batch when available.
- Prefer datasets that are realistic to process within a portfolio project.
- Prefer datasets whose sample definitions and preprocessing history can be understood from the accompanying record or publication.

## Metadata To Inspect Carefully

- case and control definitions
- age distribution
- sex balance
- smoking information
- medication or treatment status
- inflammatory or clinical activity measures
- batch or plate variables
- missingness or unclear sample annotations

## Raw Data Availability Notes

- If raw IDAT files are available, the workflow can include more explicit preprocessing and normalization decisions.
- If only processed matrices are available, the project can still be useful, but preprocessing claims must be limited to what can be verified from the source documentation.

## Notes To Verify Before Analysis

- Does the dataset truly use blood-derived samples rather than synovium or mixed tissues?
- Is the platform clearly identified and supported by current Bioconductor tooling?
- Are case and control groups large enough for a modest EWAS-style comparison?
- Are there enough covariates available to discuss major confounding risks responsibly?
- Is there any indication of duplicated samples, pooled samples, or unusual preprocessing?

## Source Notes

- GEO series page for `GSE42861` reports:
  - rheumatoid arthritis peripheral blood leukocyte methylation
  - Illumina 450K platform
  - 689 total samples
  - downloadable raw IDAT archive and processed matrices
- A later secondary analysis using `GSE42861` describes the cohort as 354 ACPA-associated RA cases and 335 controls.
- No data have been downloaded into this repository yet.
