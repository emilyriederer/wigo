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
eng_wigo_diff <- function(options) {

  # evaluate code passed to chunk ----
  if (identical(options$eval, TRUE)) {
    eval(parse(text = paste(options$code, collapse = "\n")),
         envir = knitr::knit_global())
  }

  # capture current enviornments ----
  obj_names <- setdiff(ls(envir = knitr::knit_global()), c("options", "knitr_wigo_eng_df"))
  curr_env <- tbl_environ(obj_names, chunk_name = options$label)

  # merge former and current environments ----
  prev_env <- tryCatch(get('knitr_wigo_eng_df', knitr::knit_global()), error = function(e) NULL)
  cmbd_env <- rbind(prev_env, curr_env, make.row.names = FALSE)

  # determine status of each variable ----
  mtdat <- paste(cmbd_env$type, cmbd_env$class, cmbd_env$dim, cmbd_env$raw_sz, sep = ';')
  n_totl <- aggregate(mtdat, by = list(name = cmbd_env$name), FUN = length)
  n_dist <- aggregate(mtdat, by = list(name = cmbd_env$name), FUN = function(x) length(unique(x)))
  new <- intersect(n_totl$name[n_totl$x == 1], cmbd_env$name[cmbd_env$created == options$label])
  rmd <- intersect(n_totl$name[n_totl$x == 1], cmbd_env$name[cmbd_env$created != options$label])
  mod <- intersect(n_totl$name[n_totl$x == 2], n_dist$name[n_dist$x == 2])
  stb <- intersect(n_totl$name[n_totl$x == 2], n_dist$name[n_dist$x == 1])

  # piece together output ----
  output <- rbind(
    curr_env[curr_env$name %in% c(new, mod),],
    prev_env[prev_env$name %in% c(rmd, mod),],
    make.row.names = FALSE)
  history <- rbind(
    curr_env[curr_env$name %in% c(new, mod),],
    prev_env[prev_env$name %in% c(stb),],
    make.row.names = FALSE)

  # format output ----
  output$status <- if (nrow(output) > 0) 'modified' else character(0)
  output$status[output$name %in% new] <- 'created'
  output$status[output$name %in% rmd] <- 'removed'
  output <- output[,c('status','name', 'type', 'class', 'dim', 'size', 'created')]
  output <- output[order(output$status, output$name),]

  # changes for color ----
  if (nrow(output) > 0) {
    colors <- rep('blue', length(output$status))
    colors[output$status == 'created'] <- 'green'
    colors[output$status == 'removed'] <- 'red'
    output$status <- kableExtra::cell_spec(output$status, "html", color = colors)
  }

  # save output ----
  assign("knitr_wigo_eng_df", history, envir = knitr::knit_global())
  out_tbl <- fmt_tbl(output, chunk_name = options$label)

  # reconfigure and return ----
  options$engine <- 'r' # change lang eng for formatting, folding, etc.
  options$results <- 'asis' # output results as-is for kableExtra formatting
  knitr::engine_output(options, options$code, out_tbl)

}
