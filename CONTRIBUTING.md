# Contributing

## Git

Please create a branch or fork based on `develop` for your development, and make a [pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) back to `develop` with your edits.

In the pull request, please explain what changes you have made and why.


## Package management

Please do not use `install.packages`, but instead use `renv::install` as detailed [here](https://rstudio.github.io/renv/index.html).

The exception to this is installing `renv` itself!

Ensure `renv.lock` is kept up to date by calling `renv::update()` and `renv::lock()` regularly.

In the code, please use `library(package)` sparingly, and opt instead for the more explicit `package::function` syntax for packages that are only used a handful of times.

## Style and formatting

- Run `Rscript pre-commit.R` and ensure that all tests pass and there are no styling/linting errors

This can be done either from an R session (anywhere inside the repository)

```R
source("pre-commit.R")
```

or from the command line (in the repo root)

```sh
Rscript pre-commit.R
```

## Changes to `model/`

If you change any of the code in the `R/` directory (i.e. the package source), please complete these steps (in the `model/` directory) before committing any changes:

1. Write/update documentation

2. Write/update tests

3. Regenerate the `NAMESPACE` file

```R
devtools::document()
```

4. Run some checks (in particular look for any errors and warnings)

```R
devtools::check()
```

5. Run the pre-commit script


## Code of conduct

To do.
