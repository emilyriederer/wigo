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

  knitr::knit_engines$set(wigo = wigo::eng_wigo,
                          wigo_diff = wigo::eng_wigo_diff)

}

# Internal helper function for engine ----

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

#' Create `data.frame` representation of current environment
#' @keywords internal
tbl_environ <- function(obj_names, environ = knitr::knit_global()) {

  obj_types <- vapply(obj_names, FUN = function(x) typeof(get(x, envir = environ)), character(1))
  obj_class <- vapply(obj_names, FUN = function(x) class(get(x, envir = environ)), character(1))
  obj_dimns <- vapply(obj_names, FUN = function(x) get_dimn(get(x, envir = environ)), character(1))
  obj_rawsz <- vapply(obj_names, FUN = function(x) object.size(get(x, envir = environ)), numeric(1))
  obj_size  <- vapply(obj_names, FUN = function(x) get_size(get(x, envir = environ)), character(1))
  out <- data.frame(name    = obj_names,
                    type    = obj_types,
                    class   = obj_class,
                    dim     = obj_dimns,
                    raw_sz  = obj_rawsz,
                    size    = obj_size,
                    stringsAsFactors = FALSE,
                    row.names = NULL)
  return(out)

}
