# Dataset Notes

## Purpose

This document is for tracking candidate public datasets, inclusion criteria, accession IDs, platform details, and any important metadata limitations.

## Likely Dataset Template

- GEO accession:
- Disease:
- Tissue/source:
- Platform:
- Sample size:
- Case/control structure:
- Metadata or covariates to inspect:
- Raw data availability:
- Processed data availability:
- Likely analysis caveats:
- Notes to verify before analysis:

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

## Notes

No dataset has been downloaded or finalized yet.
