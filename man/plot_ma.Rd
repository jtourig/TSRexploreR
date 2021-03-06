% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/diff_exp_plots.R
\name{plot_ma}
\alias{plot_ma}
\title{MA Plot}
\usage{
plot_ma(
  experiment,
  data_type = c("tss", "tsr", "tss_features", "tsr_features"),
  de_comparisons = "all",
  ncol = 1,
  log2fc_cutoff = 1,
  fdr_cutoff = 0.05,
  ...
)
}
\arguments{
\item{experiment}{TSRexploreR object.}

\item{data_type}{Either 'tss', 'tsr', 'tss_features', or 'tsr_features'.}

\item{de_comparisons}{Character vector of differential expression comparisons to plot.}

\item{ncol}{Integer specifying the number of columns to arrange multiple plots.}

\item{log2fc_cutoff}{Differential features not meeting this |Log2 FC| threshold will not be considered.}

\item{fdr_cutoff}{Differential features not meeting this significance threshold will not be considered.}

\item{...}{Arguments passed to geom_point.}
}
\value{
ggplot2 object of MA plot.
}
\description{
Generate an MA plot for differential TSSs, TSRs, or genes/transcripts.
}
\details{
This function generates an MA plot of the results from differential analysis of 
TSSs, TSRs, or genes/transcripts.
}
