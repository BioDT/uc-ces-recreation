renv::status()

style <- styler::tidyverse_style(
    indent_by = 4L,
    start_comments_with_one_space = TRUE
)

styler::style_pkg(
    transformers = style
)

lintr::lint_package()
