#' An environment reporting engine for knitr
#'
#' This provides an engine for `knitr` which executes all underlying R code
#' but instead of outputting code results outputs a report about the environment
#' and changes to its states. This can be useful to determine what is going on
#' when an RMarkdown has unexpected behavior or when reading an RMarkdown for the
#' first time.
#'
#' The engine can be called for all chunks by setting
#'
#' ```
#' library(wigo)
#' register_eng_wigo()
#  knitr::opts_chunk$set(engine = 'wigo')
#' ```
#'
#' at the top of your RMarkown, or by putting `engine = wigo` within the header
#' of each individual R chunk.
#'
#' @param options Chunk options provided by `knitr`
#'
#' @export
eng_wigo <- function(options) {

  # evaluate code passed to chunk ----
  if (identical(options$eval, TRUE)) {
    eval(parse(text = paste(options$code, collapse = "\n")),
         envir = knitr::knit_global())
  }

  # capture current enviornments ----
  obj_names <- setdiff(ls(envir = knitr::knit_global()), c("options", "eng_wigo", "knitr_wigo_eng_df"))
  out <- tbl_environ(obj_names)

  # dedup from previous records ----
  prev_env <- tryCatch(get('knitr_wigo_eng_df', knitr::knit_global()), error = function(e) NULL)
  comb_env <- rbind(prev_env, out, make.row.names = FALSE)
  whch_dup <- duplicated(comb_env[,c('name', 'type','class', 'dim', 'raw_sz', 'size')])
  combined <- comb_env[!whch_dup,]
  row.names(combined) <- NULL

  # preserve history and create output ----
  assign("knitr_wigo_eng_df", combined, envir = knitr::knit_global())
  combined <- combined[,c('name', 'type', 'class', 'dim', 'size', 'created')]
  out_tbl <- knitr::kable(combined, row.names = FALSE)

  # reset engine to R for code formatting, folding, etc. ----
  options$engine <- 'r'

  # return output ----
  knitr::engine_output(options, options$code, out_tbl)

}

#' Convenience function to expose wigo as a knitr engine
#'
#' This is a basic wrapper around `knitr::knit_engines$set` to register `wigo`
#' as a valid and callable language engine for knitting an RMarkdown
#'
#' @return No return
#' @export
#'
#' @examples
#' \dontrun{register_eng_wigo()}
register_eng_wigo <- function() {

  knitr::knit_engines$set(wigo = wigo::eng_wigo)

}


