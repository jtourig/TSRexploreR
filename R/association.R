#' Associate TSSs
#'
#' @description
#' Associate TSSs with TSRs
#'
#' @importFrom plyranges join_overlap_left_directed
#'
#' @inheritParams common_params
#' @param sample_list List with TSRs as names and TSSs as vector.
#'   If NULL will associate TSSs with TSRs from the sample of the same name.
#'
#' @details
#' TSRexploreR provides many options for the import and merging of TSSs and TSRs.
#' Because of this, TSS samples must be associated with TSR samples after TSR import,
#'   TSR merging, or TSS clustering using this function.
#' This adds an extra workflow step, but provides more analytical flexibility.
#' Each TSS with genomic coordinates overlapping those of a TSR in the specified TSR sample
#'   will be linked to that TSR.
#' TSSs not overlapping a TSR in the specified sample will not be associated with any TSR.
#'
#' TSS samples can be associated with TSR samples using a list or sample sheet.
#' 'sample_list' should be a named list of character vectors, with the names being the TSR
#'   sample names and the character vectors as the TSS samples(s) that should be associated with
#'   each TSR sample. If no sample list is provided, the function will automatically associate
#'   TSSs with the TSRs from the sample of the same name.
#'   
#' @examples
#' TSSs <- system.file("extdata", "S288C_TSSs.RDS", package="TSRexploreR")
#' TSSs <- readRDS(TSSs)
#' exp <- tsr_explorer(TSSs)
#' exp <- format_counts(exp, data_type="tss")
#' exp <- tss_clustering(exp)
#' exp <- associate_with_tsr(exp, sample_list=list(
#'   "S288C_WT_1"="S288C_WT_1", "S288C_WT_2"="S288C_WT_2", "S288C_WT_3"="S288C_WT_3",
#'   "S288C_D_1"="S288C_D_1", "S288C_D_2"="S288C_D_2", "S288C_D_3"="S288C_D_3"
#' ))
#'
#' @seealso
#' \code{\link{add_sample_sheet}} to add a sample sheet to the TSRexploreR object.
#'
#' @rdname associate_with_tsr-function
#' @export

associate_with_tsr <- function(
  experiment,
  sample_list=NULL
) {

  ## Check inputs.
  assert_that(is(experiment, "tsr_explorer"))
  assert_that(
    is.null(sample_list) ||
    (is.list(sample_list) && has_attr(sample_list, "names"))
  )

  ## Get TSSs.
  if (!is.null(sample_list)) {
    tss <- map(sample_list, function(samples) {
      map(samples, ~extract_counts(experiment, "tss", .x, FALSE))
    })
  } else {
    tss <- experiment@counts$TSSs$raw %>%
      imap(~purrr::set_names(list(.x), .y))
  }

  ## Get TSRs.
  if (!is.null(sample_list)) {
    tsr <- map(
      sample_list,
      ~extract_counts(experiment, "tsr", .x, FALSE)
    )
  } else {
    tsr <- copy(experiment@counts$TSRs$raw)
  }

  ## Associate TSSs with TSRs.
  tss <- imap(tsr, function(tsr, tsr_name) {
    tsr[, tsr_sample := tsr_name]
    setkey(tsr, seqnames, strand, start, end)
    tss <- tss[[tsr_name]]
    tss <- map(tss, function(x) {
      setkey(x, seqnames, strand, start, end)
      overlap <- foverlaps(x, tsr)
      overlap[, c("start", "end") := NULL]
      setnames(
        overlap,
        old=c(
          "width", "n_unique", "FHASH", "i.start", "i.end",
          "i.width", "i.FHASH", "score", "i.score"
        ),
        new=c(
          "tsr_width", "tsr_n_unique", "TSR_FHASH", "start",
          "end", "width", "FHASH", "tsr_score", "score"
        )
      )
      if (any(colnames(x) == "normalized_score")) {
        setnames(
          overlap,
          old=c("normalized_score", "i.normalized_score"),
          new=c("tsr_normalized_score", "normalized_score")
        )
      }
      overlap <- overlap %>%
        as_granges %>%
        sort %>%
        as.data.table
      return(overlap)
    })
  })
  tss <- flatten(tss)

  ## Add TSSs back to the TSRexploreR object.
  experiment <- set_count_slot(
    experiment, tss, "counts", "tss", "raw"
  )
  return(experiment)
}
