#' Threshold Exploration
#'
#' Explore raw read count thresholds thresholds.
#'
#' @importFrom purrr map_df
#'
#' @inheritParams common_params
#' @param max_threshold Thresholds from 1 to max_threshold will be explored
#' @param steps Steps to get the threshold values

#' @details
#' All TSS mapping technologies have some degree of spurious background reads.
#' tsr_explorer allows for basic thresholding of data by requiring
#'   a minimum number of reads for a TSS to be considered.
#'
#' An easy way to pick a threshold is with the threshold plot generated
#'   by 'plot_exploration_threshold'.
#' This plot shows the proportion TSS positions that are promoter-proximal when
#'   various threshold values are tested.
#' 'max_threshold' defines the maximum threshold value that will be analyzed.
#'
#' @return data.frame containing information for each threshold and sample
#'
#' @examples
#' TSSs <- system.file("extdata", "S288C_TSSs.RDS", package="TSRexploreR")
#' TSSs <- readRDS(TSSs)
#' tsre_exp <- tsr_explorer(TSSs)
#' tsre_exp <- format_counts(tsre_exp, data_type="tss")
#' annotation <- system.file("extdata", "S288C_Annotation.gtf", package="TSRexploreR")
#' tsre_exp <- annotate_features(
#'   tsre_exp, annotation_data=annotation,
#'   data_type="tss", feature_type="transcript"
#' )
#' thresh_results <- explore_thresholds(tsre_exp)
#'
#' @seealso
#' \code{\link{plot_threshold_exploration}} to plot the results.
#'
#' @rdname explore_thresholds-function
#' @export

explore_thresholds <- function(
  experiment,
  max_threshold=25,
  steps=0.5,
  samples="all",
  use_normalized=FALSE
) {

  ## Check inputs.
  assert_that(is(experiment, "tsr_explorer"))
  assert_that(is.numeric(max_threshold) && max_threshold >= 5)
  assert_that(is.character(samples))
  assert_that(is.numeric(steps) && steps >= 0.1)
  assert_that(is.flag(use_normalized))

  ## Get settings information.
  feature_type <- experiment@settings$annotation[["feature_type"]]
  feature_type <- ifelse(feature_type == "transcript", "transcriptId", "geneId")

  ## Get appropriate samples.
  select_samples <- extract_counts(experiment, "tss", samples, use_normalized)
  select_samples <- rbindlist(select_samples, idcol="sample")

  ## Get information needed for threshold plot.
  summarized_data <- map_df(seq(1, max_threshold, steps), function(x) {
    filtered <- select_samples[score >= x]
    filtered[,
      promoter_proximity := ifelse(
        simple_annotations == "Promoter",
        "n_promoter_proximal", "n_promoter_distal"
      )
    ]
    filtered[,
      n_features := uniqueN(get(feature_type)),
      by=sample
    ]

    feature_stats <- filtered[,
      .(n_features, count=.N),
      by=.(sample, promoter_proximity)
    ]
    feature_stats <- unique(feature_stats)

    feature_stats <- dcast(
      feature_stats, sample + n_features ~ promoter_proximity,
      value.var="count"
    )

    feature_stats[,
      c("n_total", "frac_promoter_proximal", "threshold") := list(
        n_promoter_proximal + n_promoter_distal,
        n_promoter_proximal / (n_promoter_proximal + n_promoter_distal),
        x
      )
    ]
  })

  ## Set order of samples if specified.
  if (!all(samples == "all")) {
    summarized_data[, sample := factor(sample, levels=samples)]
  }

  ## Return results.
  return(summarized_data)
}

#' Plot Threshold Exploration
#'
#' Make a plot to explore threshold values.
#'
#' @inheritParams common_params
#' @param threshold_data Tibble of threshold exploration data from explore_thresholds
#' @param point_size The size of the points on the plot
#' @param ... Arguments passed to geom_point
#'
#' @details
#' We have found that a threshold of 3 often provides an appropriate balance between
#'   a high promoter-proximal fraction (>= 0.8) and the number of unique genes or
#'   transcripts with at least one unique TSS.
#'
#' @return ggplot2 object containing the threshold exploration plot
#'
#' @examples
#' TSSs <- system.file("extdata", "S288C_TSSs.RDS", package="TSRexploreR")
#' TSSs <- readRDS(TSSs)
#' tsre_exp <- tsr_explorer(TSSs)
#' tsre_exp <- format_counts(tsre_exp, data_type="tss")
#' annotation <- system.file("extdata", "S288C_Annotation.gtf", package="TSRexploreR")
#' tsre_exp <- annotate_features(
#'   tsre_exp, annotation_data=annotation,
#'   data_type="tss", feature_type="transcript"
#' )
#' thresh_results <- explore_thresholds(tsre_exp)
#' plot_threshold_exploration(thresh_results)
#'
#' @seealso \code{\link{explore_thresholds}} for initial calculations.
#'
#' @rdname plot_threshold_exploration-function
#' @export

plot_threshold_exploration <- function(
  threshold_data,
  ncol=1,
  point_size=1,
  ...
) {

  ## Check inputs.
  assert_that(is.data.frame(threshold_data))
  assert_that(is.count(ncol))
  assert_that(is.numeric(point_size) && point_size > 0)

  ## Plot data.
  p <- ggplot(threshold_data, aes(x=.data$threshold, y=.data$frac_promoter_proximal)) +
    geom_line(color="lightgrey") +
    geom_point(aes(color=.data$n_features), size=point_size, ...) +
    theme_bw() +
    xlab("Count Threshold") +
    ylab("Fraction of Promoter Proximal TSSs") +
    facet_wrap(. ~ sample, ncol=ncol)

  return(p)
}

#' Apply a threshold to TSSs or TSRs
#'
#' @inheritParams common_params
#' @param n_samples Number of samples threshold must be reached to keep TSS.
#'   By default set to 1 sample. A NULL value will result in all samples being
#'   required to have read counts above threshold.
#'
#' @export

apply_threshold <- function(
  experiment,
  threshold,
  n_samples=1,
  use_normalized=FALSE
) {

  ## Check inputs.
  assert_that(is(experiment, "tsr_explorer"))
  assert_that(is.numeric(threshold) && threshold > 0)
  assert_that(is.null(n_samples) || is.count(n_samples))
  assert_that(is.flag(use_normalized))

  ## Retrieve selected samples.
  select_samples <- extract_counts(experiment, "tss", "all", use_normalized)

  ## Convert selected samples to count matrix.
  count_mat <- .count_matrix(select_samples, "tss", use_normalized)

  ## Filter TSSs below threshold.
  if (!is.null(n_samples)) {
    count_mat <- count_mat[rowSums(count_mat >= threshold) >= n_samples, ]
  } else {
    count_mat <- count_mat[rowSums(count_mat >= threshold) == ncol(count_mat), ]
  }

  ## Keep only surviving TSSs in each sample.
  select_samples <- map(select_samples, function(x) {
    x <- x[FHASH %in% rownames(count_mat)]
    return(x)
  })

  ## Add the data back to the object.
  experiment@counts$TSSs$raw <- select_samples

  ## Return the TSRexploreR object.
  return(experiment)
}
