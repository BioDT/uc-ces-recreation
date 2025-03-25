style <- styler::tidyverse_style(
    indent_by = 4L,
    start_comments_with_one_space = TRUE
)

styler::style_dir("shiny_app", transformers = style, exclude_files = list("content.R", "theme.R"))
lintr::lint_dir("shiny_app", exclusions = list("renv", "content.R", "theme.R"))
styler::style_dir("cli", transformers = style)
lintr::lint_dir("cli")

setwd("model")
devtools::document()
testthat::test_dir("tests/testthat")
styler::style_pkg(transformers = style)
lintr::lint_package()
