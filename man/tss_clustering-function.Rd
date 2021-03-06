% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/tss_clustering.R
\name{tss_clustering}
\alias{tss_clustering}
\title{TSS Clustering}
\usage{
tss_clustering(
  experiment,
  samples = "all",
  threshold = NULL,
  n_samples = NULL,
  max_distance = 25,
  max_width = NULL
)
}
\arguments{
\item{experiment}{TSRexploreR object.}

\item{samples}{A vector of sample names to analyze.}

\item{threshold}{TSSs or TSRs with a score below this value will not be considered.}

\item{n_samples}{Keep TSS if threshold number of reads are present in n_samples
number of samples.}

\item{max_distance}{Maximum allowable distance between TSSs for clustering.}

\item{max_width}{Maximum allowable TSR width.}
}
\value{
TSRexploreR object with TSRs.
}
\description{
Basic distance and threshold-based clustering of TSSs.
}
\details{
This function clusters TSSs into Transcription Start Regions (TSRs). TSSs are 
clustered if their score is greater than or equal to 'threshold' and are less 
than or equal to 'max_distance' from each other. The clustered TSSs cannot
encompass more than 'max_width' bases.
}
\examples{
TSSs <- system.file("extdata", "S288C_TSSs.RDS", package="TSRexploreR")
TSSs <- readRDS(TSSs)
exp <- tsr_explorer(TSSs)
exp <- format_counts(exp, data_type="tss")
exp <- tss_clustering(exp)

}
