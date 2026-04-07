# Interpretation Notes

## Guiding Principle

This project should avoid overclaiming. Blood DNA methylation associations in inflammatory disease contexts are often difficult to disentangle from cell composition, immune activation, treatment, and other confounding factors.

## Major Interpretation Risks

### Cell Composition

Whole-blood methylation profiles are highly sensitive to the relative abundance of immune cell types. An apparent case-control signal may reflect differences in neutrophils, lymphocytes, monocytes, or other populations rather than locus-specific disease biology within a stable cell type.

### Inflammation

Inflammatory state can influence methylation patterns directly or indirectly through shifts in circulating cell populations. In diseases such as rheumatoid arthritis, this makes it difficult to separate disease status from broader immune activation.

### Smoking

Smoking is a strong and well-known source of blood methylation variation. If smoking status is missing, incomplete, or imbalanced between groups, it can create misleading disease-associated patterns.

### Age

Age is strongly associated with methylation across the genome. Even moderate age imbalance between cases and controls can distort interpretation if not addressed in the design or discussion.

### Treatment Effects

Medication exposure may influence immune state and methylation patterns. In case-control datasets, treatment can be especially hard to separate from disease duration or severity.

### Causality Limits

Case-control methylation studies are usually observational and cross-sectional. Even a robust association does not establish whether methylation change is causal, consequential, compensatory, or simply correlated with another process.

## Points To Revisit During Analysis

- Are observed differences robust after accounting for available covariates?
- Could the result primarily reflect shifts in blood cell populations?
- Are smoking, age, sex, medication, or batch plausible alternative explanations?
- Is the dataset large enough to support stable inference?
- Are enrichment results being described as exploratory rather than definitive?

## Reporting Style

- Use cautious language such as "associated with" rather than "caused by".
- Separate statistical findings from biological interpretation.
- Clearly identify limitations in metadata and study design.
- Avoid implying diagnostic or therapeutic relevance without strong evidence.
