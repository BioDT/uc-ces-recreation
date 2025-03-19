style <- styler::tidyverse_style(
  indent_by = 4L,
  start_comments_with_one_space = TRUE
)

root <- rprojroot::find_root(rprojroot::is_git_root)

# Model
print("------------------ Model -----------------")
setwd(file.path(root, "model"))
renv::status()
testthat::test_dir("tests/testthat")
styler::style_pkg(transformers = style)
lintr::lint_package()

# CLI
print("------------------ cli -----------------")
setwd(file.path(root, "cli"))
renv::status()
styler::style_pkg(transformers = style)
lintr::lint_package()

# shiny
print("------------------ shiny_app -----------------")
setwd(file.path(root, "shiny_app"))
renv::status()
styler::style_pkg(transformers = style)
lintr::lint_package()
