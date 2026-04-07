# Project Scope

## Project Question

Can a small, reproducible R workflow be built to explore differential blood DNA methylation between public case and control samples, with rheumatoid arthritis as the likely use case, while maintaining cautious interpretation of confounding and cell-composition effects?

## Rationale

Public methylation datasets are useful for demonstrating data handling, quality control, modeling, and biological interpretation skills, but they also require careful framing. This project is intentionally scoped to be realistic for a portfolio: one dataset, one clear case-control comparison, transparent scripts, and modest claims. The emphasis is on showing good analytical judgment rather than maximizing novelty.

## Objectives

- Select and document a suitable public blood DNA methylation dataset.
- Build a clean EWAS-oriented analysis structure in R.
- Perform preprocessing, QC, normalization, and confounder-aware modeling.
- Summarize differential methylation results without overstating biological meaning.
- Create a portfolio-ready repository that is easy to explain to employers.

## In Scope

- Public blood DNA methylation case-control data
- Reproducible scripted analysis in R
- QC summaries and exploratory plots
- Probe filtering and normalization decisions
- Covariate handling and design matrix construction
- Differential methylation analysis
- CpG annotation and cautious enrichment analysis
- Documentation of assumptions and limitations

## Out of Scope

- Multi-cohort meta-analysis
- Novel method development
- Wet-lab validation
- Causal claims about disease mechanisms
- Clinical biomarker development claims
- Large-scale deployment or automation beyond a portfolio-scale workflow

## Expected Outputs

- A structured GitHub repository
- Ordered analysis scripts and helper functions
- QC outputs and figures
- Differential methylation result tables
- Annotation and enrichment summaries
- Documentation describing dataset choice, modeling decisions, and interpretation limits
- A short, portfolio-ready narrative explaining what was done and what cannot be concluded

## Scientific Caveats

- Blood methylation signals are strongly influenced by cellular composition.
- Case-control differences may reflect inflammation, medication, smoking, age, sex, or technical effects.
- Public metadata may be incomplete or uneven in quality.
- Small sample sizes can limit power and stability.
- Any findings should be framed as exploratory and context-dependent.
- Annotation and enrichment steps can help summarize results, but they do not by themselves establish mechanism.
