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
  out <- tbl_environ(obj_names, chunk_name = options$label)

  # dedup from previous records ----
  prev_env <- tryCatch(get('knitr_wigo_eng_df', knitr::knit_global()), error = function(e) NULL)
  comb_env <- rbind(prev_env, out, make.row.names = FALSE)
  whch_dup <- duplicated(comb_env[,c('name', 'type','class', 'dim', 'raw_sz', 'size')])
  combined <- comb_env[!whch_dup,]
  row.names(combined) <- NULL

  # preserve history and create output ----
  assign("knitr_wigo_eng_df", combined, envir = knitr::knit_global())
  combined <- combined[,c('name', 'type', 'class', 'dim', 'size', 'created')]
  out_tbl <- fmt_tbl(combined, chunk_name = options$label)

  # reconfigure and return ----
  options$engine <- 'r' # change lang eng for formatting, folding, etc.
  options$results <- 'asis' # output results as-is for kableExtra formatting
  knitr::engine_output(options, options$code, out_tbl)

}




