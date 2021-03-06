#' Generate Correlation Matrix
#'
#' Calculate a correlation matrix to assess between-sample concordance of TSSs or TSRs.
#'
#' @inheritParams common_params
#' @param data_type Whether to make scatter plots from TSS, TSR, or RNA-seq & 5' data.
#' @param correlation_metric Whether to use Spearman or Pearson correlation.
#'
#' @return Correlation matrix

find_correlation <- function(
  experiment,
  data_type=c("tss", "tsr", "features"),
  samples="all",
  correlation_metric="pearson"
) {

  ## Select appropriate data.
  normalized_counts <- switch(
    data_type,
    "tss"=assay(experiment@correlation$TSSs$matrix, "tmm"),
    "tsr"=assay(experiment@correlation$TSRs$matrix, "tmm"),
    "features"=assay(experiment@correlation$features$matrix, "tmm")
  )

  type_color <- switch(
    data_type,
    "tss"="#431352",
    "tsr"="#34698c",
    "features"="#29AF7FFF"
  )

  ## Select all samples if "all" specified.
  if (samples == "all") samples <- colnames(normalized_counts)
  normalized_counts <- normalized_counts[, samples]

  ## Make correlation matrix.
  correlation <- normalized_counts %>%
    .[, samples] %>%
    cor(method=correlation_metric) %>%
    as_tibble(.name_repair="unique", rownames="sample_1") %>%
    pivot_longer(!sample_1, "sample_2", "cor")

  ## Place correlation values into proper slot.
  if (data_type == "tss") {
    experiment@correlation$TSSs$cor_matrix <- correlation
  } else if (data_type == "tsr") {
    experiment@correlation$TSRs$cor_matrix <- correlation
  } else {
    experiment@correlation$features$cor_matrix <- correlation
  }

  return(experiment)    
}

#' Plot Sample Correlation
#'
#' Heatmaps and/or scatter plots to explore replicate concordance of TSSs or TSRs.
#'
#' @importFrom ComplexHeatmap Heatmap
#' @importFrom circlize colorRamp2 
#' @importFrom viridis viridis
#' @importFrom grid gpar grid.text
#'
#' @inheritParams common_params
#' @param data_type Whether to make scatter plots from TSS, TSR, or RNA-seq & 5' data.
#' @param correlation_metric Whether to use Spearman or Pearson correlation.
#' @param font_size The font size for the heatmap tiles.
#' @param cluster_samples Logical for whether hierarchical clustering should be performed
#'   on rows and columns.
#' @param heatmap_colors Vector of colors for heatmap.
#' @param show_values Logical for whether to show correlation values on the heatmap.
#' @param ... Additional arguments passed to ComplexHeatmap::Heatmap.
#'
#' @details
#' Correlation plots are a good way to assess the similarity of samples.
#' This can be useful to determine replicate concordance and for the initial assessment of
#'   differences between samples from different conditions.
#' This function generates various plots using a previously TMM- or MOR-normalized count matrix.
#
#' Pearson correlation is recommended for samples from the same technology due to 
#' the expectation of a roughly linear relationship between the magnitudes of values 
#' for each feature. Spearman correlation is recommended for samples from different technologies,
#' such as STRIPE-seq vs. CAGE, due to the expectation of a roughly linear relationship 
#' between the ranks, rather than the specific values, of each feature.
#'
#' @return ggplot2 object of correlation heatmap.
#'
#' @examples
#' TSSs <- system.file("extdata", "S288C_TSSs.RDS", package="TSRexploreR")
#' TSSs <- readRDS(TSSs)
#' exp <- tsr_explorer(TSSs)
#' exp <- format_counts(exp, data_type="tss")
#' exp <- normalize_counts(exp, data_type="tss")
#' plot_correlation(exp, data_type="tss")
#'
#' @seealso \code{\link{count_matrix}} to generate the count matrices.
#'   \code{\link{tmm_normalize}} to TMM normalize the matrices.
#'
#' @rdname plot_correlation-function
#' @export

plot_correlation <- function(
  experiment,
  data_type=c("tss", "tsr", "tss_features", "tsr_features"),
  samples="all",
  correlation_metric="pearson",
  threshold=NULL,
  use_normalized=TRUE,
  font_size=12,
  cluster_samples=FALSE,
  heatmap_colors=NULL,
  show_values=TRUE,
  ...
) {

  ## Check inputs.
  if (!is(experiment, "tsr_explorer")) stop("experiment must be a TSRexploreR object")
  data_type <- match.arg(data_type, c("tss", "tsr", "tss_features", "tsr_features"))
  assert_that(is.character(samples))
  correlation_metric <- match.arg(correlation_metric, c("pearson", "spearman"))
  assert_that(is.numeric(font_size) && font_size > 0)
  assert_that(is.flag(cluster_samples))
  assert_that(is.null(heatmap_colors) | is.character(heatmap_colors))
  assert_that(is.flag(show_values))
  assert_that(is.flag(use_normalized))
  assert_that(
    is.null(threshold) ||
    (is.numeric(threshold) && threshold > 0)
  )

  ## Get data from proper slot.
  normalized_counts <- experiment %>%
    extract_counts(data_type, samples) %>%
    .count_matrix("tss", use_normalized)
  
  sample_names <- colnames(normalized_counts)

  ## Define default color palette.
  color_palette <- switch(
    data_type,
    "tss"="#431352",
    "tsr"="#34698c",
    "tss_features"="#29AF7FFF",
    "tsr_features"="#29AF7FFF"
  )

#  ## Log2 + 1 transform data if indicated.
#  pre_transformed <- copy(normalized_counts)
#  if (log2_transform) {
#    normalized_counts <- log2(normalized_counts + 1)
#  }

  ## Correlation Matrix.
  cor_mat <- cor(normalized_counts, method=correlation_metric)

  ## ComplexHeatmap Correlation Plot.
  heatmap_args <- list(
    cor_mat,
    row_names_gp=gpar(fontsize=font_size),
    column_names_gp=gpar(fontsize=font_size)
  )
  if (!cluster_samples) {
    heatmap_args <- c(heatmap_args, list(cluster_rows=FALSE, cluster_columns=FALSE))
  }
  if (!is.null(heatmap_colors)) {
    heatmap_args <- c(heatmap_args, list(col=heatmap_colors))
  }
  if (show_values) {
    heatmap_args <- c(heatmap_args, list(
      cell_fun=function(j, i, x, y, width, height, fill) {
        grid.text(sprintf("%.2f", cor_mat[i, j]), x, y, gp=gpar(fontsize=font_size))
      }
    ))
  }

  p <- do.call(Heatmap, heatmap_args)

  ## Make functions for scatter plot.

  # Create custom scatter plot format.
#  custom_scatter <- function(data, mapping) {
#    ggplot(data=data, mapping=mapping) +
#      geom_point(size=pt_size, color=color_palette, stroke=0) +
#      geom_abline(intercept=0, slope=1, lty=2)
#  }
#
#  # Create custom correlation heatmap format.
#  custom_heatmap <- function(data, mapping) {
#    sample_1 <- pre_transformed[ ,str_replace(mapping$x, "~", "")]
#    sample_2 <- pre_transformed[ ,str_replace(mapping$y, "~", "")]
#
#    correlation <- cor(sample_1, sample_2, method=correlation_metric) %>%
#      round(3) %>%
#      as_tibble(name_repair="unique", rownames="sample_1") %>%
#      pivot_longer(!sample_1, "sample_2", "correlation")
#
#    ggplot(correlation, aes(x=sample_1, y=sample_2)) +
#      geom_tile(color="white", aes(fill=correlation)) +
#      geom_label(aes(label=correlation), label.size=NA, fill=NA, color="black", size=font_size) +
#      scale_fill_viridis_c(limits=c(0, 1))
#  }
#
#  ## Plot the correlation plot.   
#
#  if (correlation_plot == "scatter") {
#    p <- ggpairs(
#      normalized_counts,
#      columns=sample_names,
#      upper=list(continuous=custom_scatter),
#      lower=NULL,
#      diag=NULL,
#      ...
#    )
#  } else if (correlation_plot == "heatmap") {
#    p <- ggpairs(
#      normalized_counts,
#      columns=sample_names,
#      upper=list(continuous=custom_heatmap),
#      lower=NULL,
#      diag=NULL,
#      ...
#    )
#  } else if (correlation_plot == "combined") {
#    p <- ggpairs(
#      normalized_counts,
#      columns=sample_names,
#      upper=list(continuous=custom_heatmap),
#      lower=list(continuous=custom_scatter)#,
##      ...
#    )
#  } else if (correlation_plot == "hierarchical") {
#    corr_matrix <- pre_transformed %>%
#      cor(method=correlation_metric)
#
#    p <- Heatmap(
#      corr_matrix,
#      name=correlation_metric,
#      row_names_gp=gpar(fontsize=font_size),
#      column_names_gp=gpar(fontsize=font_size),
#      heatmap_legend_param=list(
#        title_gp=gpar(fontsize=font_size),
#        labels_gp=gpar(fontsize=font_size),
#        grid_height=unit(2, "mm"),
#        grid_width=unit(3, "mm")
#      ),
#      ...
#    )
#  }

  return(p)
}
