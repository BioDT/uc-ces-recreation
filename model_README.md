# Recreational Potential Model

## Use in other projects

If you have the repository downloaded locally, you can add the following line to your R scripts, which (unfortunately) exposes the entire namespace:

```R
devtools::install("path/to/uc-ces-recreation2/model")
```

To do
- Installation from GitHub using devtools
- Installation using renv or install.packages

## For developers

Whenever you make a change to the code, you need to regenerate the `NAMESPACE` file by running

```R
devtools::document()
```

You should also run the tests, linter, style checker,

```sh
Rscript pre-commit.R
```

