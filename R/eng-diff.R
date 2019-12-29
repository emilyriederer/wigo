#' An environment diff reporting engine for knitr
#'
#' This provides an engine for `knitr` which executes all underlying R code
#' but instead of outputting code results outputs a report about changes to
#' the environment state. This can be useful to determine what is going on
#' when an RMarkdown has unexpected behavior or when reading an RMarkdown for the
#' first time.
#'
#' The engine can be called for all chunks by setting
#'
#' ```
#' library(wigo)
#' register_eng_wigo()
#  knitr::opts_chunk$set(engine = 'wigo_diff')
#' ```
#'
#' @param options Chunk options provided by `knitr`
#'
#' @export
eng_wigo_diff <- function(options) {eng_wigo_base(options, diff = TRUE)}
