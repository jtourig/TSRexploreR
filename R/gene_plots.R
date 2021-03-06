#' Genes/Transcripts Detected
#'
#' @description
#' Get the number of genes or transcripts with an associated unique TSS or TSR.
#'
#' @inheritParams common_params
#' @param data_type Whether TSSs or TSRs should be analyzed.
#' @param ... Arguments passed to geom_col.
#'
#' @details
#' This function will returnthe number of genes or transcripts with an associated 
#' unique TSS or TSR. Information on whether the feature has a promoter-proximal 
#' TSS or TSR is included in the output for plotting purposes.
#'
#' A set of functions to control data structure for plotting are included. 'use_normalized' 
#' will use  normalized scores, which only matters if 'consider_score' is TRUE.
#' 'threshold' defines the minimum number of raw counts a TSS or TSR must have to be 
#' considered. dominant' specifies whether only the dominant TSS or TSR (determined
#' using the 'mark_dominant' function) is considered. For TSSs, this can be either 
#' dominant TSS per TSR or gene/transcript, and for TSRs it is the dominant TSR 
#' per gene/transcript. 'data_conditionals' can be used to filter, quantile, order, 
#' and/or group data for plotting.
#'
#' @return DataFrame of detected feature numbers.
#'
#' @examples
#' TSSs <- system.file("extdata", "S288C_TSSs.RDS", package="TSRexploreR")
#' TSSs <- readRDS(TSSs)
#' exp <- tsr_explorer(TSSs)
#' exp <- format_counts(exp, data_type="tss")
#' annotation <- system.file("extdata", "S288C_Annotation.gtf", package="TSRexploreR")
#' exp <- annotate_features(
#'   exp, annotation_data=annotation,
#'   data_type="tss", feature_type="transcript"
#' )
#' detected <- detect_features(exp, data_type="tss")
#'
#' @seealso
#' \code{\link{annotate_features}} to annotate the TSSs and TSRs.
#' \code{\link{plot_detected_features}} to plot numbers of detected features.
#'
#' @export

plot_detected_features <- function(
  experiment,
  samples="all",
  data_type=c("tss", "tsr"),
  threshold=NULL,
  dominant=FALSE,
  use_normalized=FALSE,
  data_conditions=NULL,
  ...
) {

  ## Check inputs.
  assert_that(is(experiment, "tsr_explorer"))
  assert_that(is.character(samples))
  data_type <- match.arg(str_to_lower(data_type), c("tss", "tsr", "tss_features", "tsr_features"))
  assert_that(is.null(threshold) || (is.numeric(threshold) && threshold >= 0))
  assert_that(is.flag(dominant))
  assert_that(is.flag(use_normalized))
  assert_that(is.null(data_conditions) || is.list(data_conditions))

  ## Get sample data.
  sample_data <- experiment %>%
    extract_counts(data_type, samples, use_normalized) %>%
    preliminary_filter(dominant, threshold)
  
  ## Apply data conditioning if requested.
  sample_data <- condition_data(sample_data, data_conditions)

  ## Rename feature column.
  walk(sample_data, function(x) {
    setnames(
      x, old=ifelse(
        experiment@settings$annotation[, feature_type] == "transcript",
        "transcriptId", "geneId"
      ),
      new="feature"
    )
  })

  ## Get feature counts.
  grouping_status <- case_when(
    !is.null(data_conditions$quantiling) ~ "row_quantile",
    !is.null(data_conditions$grouping) ~ "row_groups",
    TRUE ~ "none"
  )

  sample_data <- rbindlist(sample_data, idcol="sample")
  sample_data <- .count_features(sample_data, grouping_status)

  ## Prepare data for plotting.
  sample_data[, total := NULL]
  plot_data <- melt(
    sample_data,
    measure.vars=c("with_promoter", "without_promoter"),
    variable.name="count_type",
    value.name="feature_count"
  )
  plot_data[, count_type := factor(
    count_type, levels=c("without_promoter", "with_promoter")
  )]

  ## Order samples if required.
  if (!all(samples == "all")) {
    sample_data[, sample := factor(sample, levels=samples)]
  }

  ## Plot data.
  p <- ggplot(plot_data, aes(x=.data$sample, y=.data$feature_count, fill=.data$count_type)) +
    geom_col(position="stack", ...) +
    theme_bw() +
    ylim(c(0, NA)) +
    ylab("Feature Count") +
    xlab("Sample") +
    theme(
      axis.text.x=element_text(angle=45, hjust=1)
    )

  if (grouping_status != "none") {
    p <- p + facet_grid(fct_rev(factor(grouping)) ~ .)
  }

  return(p)

}

#' Calculate Feature Counts
#'
#' @param sample_data Sample data.
#' @param grouping_status Whether there is a grouping variable.

.count_features <- function(sample_data, grouping_status) {

  if (grouping_status != "none") {
    setnames(sample_data, old=grouping_status, new="grouping")
    sample_data <- sample_data[,
      .(grouping, promoter=any(simple_annotations == "Promoter")),
      by=.(sample, feature)
    ][,
      .(with_promoter=sum(promoter), without_promoter=.N - sum(promoter), total=.N),
      by=.(sample, grouping)
    ]
  } else {
    sample_data <- sample_data[,
      .(promoter=any(simple_annotations == "Promoter")),
      by=.(sample, feature)
    ][,
      .(with_promoter=sum(promoter), without_promoter=.N - sum(promoter), total=.N),
      by=sample
    ]
  }

  return(sample_data)
}

#' Plot Detected Features
#'
#' @description
#' Plot number of features detected per sample.
#'
#' @importFrom stringr str_to_title
#'
#' @details
#' This plotting function returns a stacked barplot showing the number of
#' features detected with and without a promoter proximal TSS or TSR. The information 
#' is first prepared using the 'detect_features' function.
#'
#' @return ggplot2 object of detected feature counts.
#'
#' @examples
#' TSSs <- system.file("extdata", "S288C_TSSs.RDS", package="TSRexploreR")
#' TSSs <- readRDS(TSSs)
#' exp <- tsr_explorer(TSSs)
#' exp <- format_counts(exp, data_type="tss")
#' annotation <- system.file("extdata", "S288C_Annotation.gtf", package="TSRexploreR")
#' exp <- annotate_features(
#'   exp, annotation_data=annotation,
#'   data_type="tss", feature_type="transcript"
#' )
#' detected <- detect_features(exp, data_type="tss")
#' plot_detected_features(detected)
#'
#' @seealso
#' \code{\link{annotate_features}} to annotate the TSSs or TSRs.
#' \code{\link{detect_features}} to determine numbers of detected features.

plot_detected_feats <- function(x) NULL
