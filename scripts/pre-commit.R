git_root <- rprojroot::find_root(rprojroot::is_git_root)

setwd(file.path(git_root))

devtools::document()

testthat::test_dir("tests/testthat")

style <- styler::tidyverse_style(
    indent_by = 4L,
    start_comments_with_one_space = TRUE
)
styler::style_pkg(transformers = style, exclude_files = list("R/app_text.R"))

lintr::lint_package(exclusions = list("renv", "R/app_text.R"))
