% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/diff_exp_plots.R
\name{plot_num_de}
\alias{plot_num_de}
\title{Plot DE Numbers}
\usage{
plot_num_de(
  experiment,
  data_type = c("tss", "tsr", "tss_features", "tsr_features"),
  de_comparisons = "all",
  log2fc_cutoff = 1,
  fdr_cutoff = 0.05,
  keep_unchanged = FALSE,
  ...
)
}
\arguments{
\item{experiment}{TSRexploreR object.}

\item{data_type}{Either 'tss', 'tsr', 'tss_features', or 'tsr_features'.}

\item{de_comparisons}{Character vector of differential expression comparisons to plot.}

\item{log2fc_cutoff}{Differential features not meeting this |Log2 FC| threshold will not be considered.}

\item{fdr_cutoff}{Differential features not meeting this significance threshold will not be considered.}

\item{keep_unchanged}{Whether to include unchanged features in the plot.}

\item{...}{Additional arguments passed to geom_col.}
}
\description{
Plot number of DE features.
}
