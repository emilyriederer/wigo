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
  obj_names <- setdiff(ls(envir = knitr::knit_global()), c("options", "eng_explain", "knitr_wigo_eng_df"))

  # record outputs ----
  obj_types <- vapply(obj_names, FUN = function(x) typeof(get(x)), character(1))
  obj_class <- vapply(obj_names, FUN = function(x) class(get(x)), character(1))
  obj_dimns <- vapply(obj_names, FUN = function(x) get_dimn(get(x)), character(1))
  obj_rawsz <- vapply(obj_names, FUN = function(x) object.size(get(x)), numeric(1))
  obj_size  <- vapply(obj_names, FUN = function(x) get_size(get(x)), character(1))
  out <- data.frame(name    = obj_names,
                    type    = obj_types,
                    class   = obj_class,
                    dim     = obj_dimns,
                    raw_sz  = obj_rawsz,
                    size    = obj_size,
                    created = rep(options$label, times = length(obj_names)),
                    stringsAsFactors = FALSE,
                    row.names = NULL)

  # dedup from previous records ----
  prev_env <- tryCatch(get('knitr_wigo_eng_df', knitr::knit_global()), error = function(e) NULL)
  comb_env <- rbind(prev_env, out, make.row.names = FALSE)
  whch_dup <- duplicated(comb_env[,c('name', 'type','class', 'dim', 'raw_sz', 'size')])
  combined <- comb_env[!whch_dup,]
  row.names(combined) <- NULL

  # preserve history and create output ----
  assign("knitr_wigo_eng_df", combined, envir = knitr::knit_global())
  out_tbl <- knitr::kable(combined[,c('name', 'type', 'class', 'dim', 'size', 'created')], row.names = FALSE)


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

# Internal helper function for engine

#' Provides `length` for all object types except `data.frame`s and `nrow x ncol` for `data.frame`
#' @keywords internal
get_dimn <- function(x) {
  ifelse('data.frame' %in% class(x),
         paste0(nrow(x),'x',ncol(x)),
         as.character(length(x)))
}

#' Format object size with different units based on size
#' @keywords internal
get_size <- function(x) {

  sz <- object.size(x)

  sz_fmt <-
         if (sz < 1000^1) {format(sz, units =  'B', standard = 'SI')}
    else if (sz < 1000^2) {format(sz, units = 'kB', standard = 'SI')}
    else if (sz < 1000^3) {format(sz, units = 'MB', standard = 'SI')}
    else if (sz < 1000^4) {format(sz, units = 'GB', standard = 'SI')}
    else                  {format(sz, units = 'TB', standard = 'SI')}

  return(sz_fmt)

}
