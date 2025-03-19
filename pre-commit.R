style <- styler::tidyverse_style(
    indent_by = 4L,
    start_comments_with_one_space = TRUE
)

renv::status()
testthat::test_dir("tests/testthat")
styler::style_pkg(transformers = style)
lintr::lint_package()

# Need to style/lint non-package directories separately
styler::style_dir("cli", transformers = style)
lintr::lint_dir("cli")
styler::style_dir("shiny_app", transformers = style)
lintr::lint_dir("shiny_app", exclusions = list("theme.R", "content.R"))
