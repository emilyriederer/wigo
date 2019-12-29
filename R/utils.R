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
