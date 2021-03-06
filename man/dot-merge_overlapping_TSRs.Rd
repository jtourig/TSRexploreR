% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/merge.R
\name{.merge_overlapping_TSRs}
\alias{.merge_overlapping_TSRs}
\title{Merge Overlapping TSRs}
\usage{
.merge_overlapping_TSRs(
  samples,
  norm_status,
  max_distance,
  experiment,
  genome_assembly
)
}
\arguments{
\item{samples}{Sample data.}

\item{norm_status}{Whether there is a normalized score column.}

\item{max_distance}{Maximum distance of TSRs to be merged.}

\item{experiment}{TSRexploreR object.}

\item{genome_assembly}{Genome assembly in FASTA or BSgenome format.}
}
\description{
Merge Overlapping TSRs
}
