% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/diff_exp_plots.R
\name{export_for_enrichment}
\alias{export_for_enrichment}
\title{Export to clusterProfiler}
\usage{
export_for_enrichment(
  experiment,
  data_type = c("tss", "tsr"),
  de_comparisons = "all",
  log2fc_cutoff = 1,
  fdr_cutoff = 0.05,
  keep_unchanged = FALSE,
  anno_categories = NULL
)
}
\arguments{
\item{experiment}{TSRexploreR object.}

\item{data_type}{Whether to export genes associated with differential TSSs or
TSRs.}

\item{de_comparisons}{Character vector of differential expression comparisons to export.}

\item{log2fc_cutoff}{Differential features not meeting this |Log2 FC| threshold will not be considered.}

\item{fdr_cutoff}{Differential features not meeting this significance threshold will not be considered.}

\item{keep_unchanged}{Logical for inclusion of genes not significantly changed in
the exported list.}

\item{Vector}{of annotation categories to keep.
If NULL no filtering by annotation type occurs.}
}
\description{
Export differential features for use in clusterProfiler term enrichment.
}
