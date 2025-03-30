style <- styler::tidyverse_style(
    indent_by = 4L,
    start_comments_with_one_space = TRUE
)

git_root <- rprojroot::find_root(rprojroot::is_git_root)

# Do the less important ones first!
setwd(file.path(git_root, "inst", "cli"))
styler::style_dir(transformers = style)
lintr::lint_dir()

setwd(file.path(git_root))
devtools::document()
testthat::test_dir("tests/testthat")
styler::style_pkg(transformers = style, exclude_files = list("R/app_text.R"))
lintr::lint_package(exclusions = list("renv", "R/app_text.R"))
