# wigo

<!-- badges: start -->
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

The goal of `wigo` is to make it easier to understand how an RMarkdown is generating its output by toggling the knit engine. `wigo` will help you understand *w*hat *i*s *g*oing *o*n in an RMarkdown document by output a table explaining the knitting state and key changes. 

Specifically, instead of normal chunk output, `wigo` output a table explaining the state containing columns for each object in the enviornment and describing its:

- status (created, modified, removed)
- name
- type
- class
- dimensions (rows x columns for dataframes and `length` otherwise)
- object size
- name of chunk in which variable was created or last modified

A new row is added to this table either when a new object is added to the environment or when the dimensions of a current object change. Currently, the actual contents of objects are not inspected.

## Installation

You can install the development version of `wigo` from GitHub with:

``` r
remotes::install_git('emily_riederer/wigo')
```

Note that this package is *extremely* experimental, untested, and subject to change.

## Example

You can toggle the language engine of your RMarkdown document to `wigo` by adding this to the set-up chunk of your RMarkdown:

```
library(wigo)
register_eng_wigo()
knitr::opts_chunk$set(engine = 'wigo')
```

to see a full description of the environment and any changes at each point in time, or

```
library(wigo)
register_eng_wigo()
knitr::opts_chunk$set(engine = 'wigo_diff')
```

to see only the environment diff. 

By doing so, you can input such as:

![](man/figures/readme-ex-input.png)

to output like:

![](man/figures/readme-ex-output.png)

# Limitations

`wigo` provides a high-level overview of changes to the environment but is not perfect. It detects and reports changes to an objects class, type, size, or dimensions, but it is not actually checking the contents of each objects. For example, in the image above, no changes are detected for `y` after we do the computation `y <- y+1` because this does not meaningfully change any of elements listed above although it clearly changes the value.

Additionally, `wigo` currently works with HTML output. 
