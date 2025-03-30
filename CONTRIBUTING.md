# Contributing

## Git

Please create a branch or fork based on `develop` for your development, and make a [pull request](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/creating-a-pull-request) back to `develop` with your edits.

In the pull request, please explain what changes you have made and why.


## Package management

Please do not use `install.packages`, but instead use `renv::install` as detailed [here](https://rstudio.github.io/renv/index.html).

The exception to this is installing `renv` itself!

Ensure `renv.lock` is kept up to date by calling `renv::update()` and `renv::lock()` regularly.


## Development checklist

After making a change, please complete these steps before committing the changes:

1. Write/update documentation

2. Write/update tests and check they pass

3. Regenerate the `NAMESPACE` file using `devtools::document()`

4. Run some checks using `devtools::check()` (in particular look for any errors and warnings)

5. Ensure the style and formatting is consistent

6. Commit your changes


## Pre-commit script

To make this easier, there is a script `pre-commit.R` that can be run before committing changes.
This can be done either from an R session (anywhere inside the repository)

```R
source("pre-commit.R")
```

or from the command line (in the repo root)

```sh
Rscript pre-commit.R
```

The script does the following:

1. Runs `devtools::document()` to regenerate the `NAMESPACE` file
2. Runs the tests using `testthat`
3. Checks for style/formatting errors using `styler` and `lintr`

What's missing from this is `devtools::check()` - that is up to you.


## Using external functions

Please do not use `library(package)`.

Instead, opt for the more explicit `package::function` syntax for packages that are only used a handful of times.

In cases where external functions are used many times, and the explicit syntax would cause readibility issues, you can flag this package for import on a per-function basis in the Roxygen2 section above the function, with the syntax `@import package`. 
See examples of this in `R/app_server.R` and `R/app_ui.R`.

## Code of conduct

To do.
