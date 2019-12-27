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
    eval(parse(text = knitr:::one_string(options$code)),
         envir = knitr::knit_global())
  }

  # capture current enviornments ----
  obj_names <- setdiff(ls(envir = knitr::knit_global()), c("options", "eng_explain", "knitr_wigo_eng_df"))

  # record outputs ----
  get_dimn <- function(x) ifelse('data.frame' %in% class(x),
                                 paste0(nrow(x),'x',ncol(x)),
                                 as.character(length(x)))
  obj_types <- vapply(obj_names, FUN = function(x) typeof(get(x)), character(1))
  obj_class <- vapply(obj_names, FUN = function(x) class(get(x)), character(1))
  obj_dimns <- vapply(obj_names, FUN = function(x) get_dimn(get(x)), character(1))
  out <- data.frame(name = obj_names,
                    type = obj_types,
                    class = obj_class,
                    dim = obj_dimns,
                    created = rep(options$label, times = length(obj_names)),
                    stringsAsFactors = FALSE,
                    row.names = NULL)

  # dedup from previous records ----
  prev_env <- tryCatch(get('knitr_wigo_eng_df', knitr::knit_global()), error = function(e) NULL)
  comb_env <- rbind(prev_env, out)
  whch_dup <- duplicated(comb_env[,c('name', 'type','class', 'dim')])
  combined <- comb_env[!whch_dup,]

  # preserve history and create output ----
  assign("knitr_wigo_eng_df", combined, envir = knitr::knit_global())
  out_tbl <- knitr::kable(combined)

  # return output ----
  knitr::engine_output(options, options$code, out_tbl)

}

#' Convenience function to expose wigo as a knitr engine
#'
#' This is a basic wrapper around `knitr::knit_engines$set` to expose `wigo`
#' as a valid and callable language engine for knitting an RMarkdown
#'
#' @return No return
#' @export
#'
#' @examples
#' \dontrun{set_eng_wigo()}
set_eng_wigo <- function() {

  knitr::knit_engines$set(wigo = wigo::eng_wigo)

}
