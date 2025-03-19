# Contributing


## Git

Please create a branch based on `develop` for your development, and make a pull request to `develop` with your edits.


## Best practices

- Please write documentation and tests for any new functionality.

- Please run `Rscript pre-commit.R` and ensure that all tests pass, the environment is consistent with the lockfile, and there are no styling/linting errors


## Changes to the files in `R/`

If you change any of the code in the `R/` directory (i.e. the package source), please complete these steps (in the repository root) before committing any changes:

```R
# Regenerate the NAMESPACE file
devtools::document()

# Check the build is successful
devtools::build()
```

For your changes to be reflected in your local development environment, you will need to also run

```R
# Install the package (omit the `quick = TRUE` if you skipped the build step)
devtools::install(quick = TRUE)
```
