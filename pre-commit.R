style <- styler::tidyverse_style(
    indent_by = 4L,
    start_comments_with_one_space = TRUE
)

git_root <- rprojroot::find_root(rprojroot::is_git_root)

# Do the less important ones first!
setwd(file.path(git_root, "cli"))
styler::style_dir(transformers = style)
lintr::lint_dir()

setwd(file.path(git_root, "shiny_app"))
styler::style_dir(transformers = style, exclude_files = list("content.R", "theme.R"))
lintr::lint_dir(exclusions = list("renv", "content.R", "theme.R"))

setwd(file.path(git_root, "model"))
devtools::document()
testthat::test_dir("tests/testthat")
styler::style_pkg(transformers = style)
lintr::lint_package()
