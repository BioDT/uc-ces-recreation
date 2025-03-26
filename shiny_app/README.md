# Shiny App

## Quickstart

In an R session, run

```R
renv::install()
```

followed by

```R
shiny::runApp("R/app.R")
```

If you prefer to run things from the shell, you can also run `./run-app.sh` (bash shell required).


## For developers

After making changes to the code, please do the following:

1. Check that the app runs correctly.

2. Run `Rscript pre-commit.R` and resolve any issues.
