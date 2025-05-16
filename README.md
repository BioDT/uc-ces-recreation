---
editor_options: 
  markdown: 
    wrap: sentence
---

# BioDT Recreation Potential model

-   Introduction to BioDT, appropriate links to UKCEH and BioDT
-   Recreational Potential is one half of the 'Cultural Ecosystem Services prototype Digital Twin' (CES pDT) developed by UKCEH.

## Overview

### Package

This repository contains an implementation of the Recreational Potential model developed by $$CITATION$$ as an `R` package.

``` r
> persona <- load_persona("path/to/personas.csv", name = "Running")
> bbox <- terra::ext(xmin, xmax, ymin, ymax)  # must be within Scotland!
> layers <- compute_potential(persona, bbox)
> names(layers)
[1] "SLSRA"                  "FIPS_N"                 "FIPS_I"                
[4] "Water"                  "Recreational_Potential"
> plot(layers$Recreational_Potential)
```

$$To do: add image$$

### App

The package comes bundled with an R Shiny app which enables users to visualise Recreational Potential values in Scotland, based on a customisable set of importance scores for 81 different items.
This was developed independently of the [official BioDT app](https://app.biodt.eu/app/biodtshiny), and was used in a 2025 study $$todo: links when complete$$.

$$To do: add image$$

A live instance of the Recreational Potential app is hosted at $$todo: link to datalabs instance$$.

### Command-line interface

The directory `inst/scripts/cli/` contains an R script that allows you to run the Recreational Potential model from the command line, providing the required inputs as arguments.

There is also a singularity container definition file which builds a container that becomes a drop-in replacement for the script.

Further details can be found in [inst/scripts/cli/README.md](inst/scripts/cli/README.md).

### Data production script

The directory `inst/scripts/data_production/` contains an R script that produces the input data for the Recreational Potential model from some pre-existing raster files.
Unfortunately at this point we do not have the full provenance of this data, but we expect to figure this out and complete the data processing pipeline in the near future.
There is also a singularity container.

Further details can be found in [inst/scripts/data_production/README.md](inst/scripts/data_production/README.md).

## For users

### Prerequisites

-   R version 4.4.x
-   Ensure you have either `remotes` or `devtools` installed (using e.g. `install.packages` or `renv::install`)
-   It is recommended to perform the following steps using an R envirnoment managed by [`renv`](https://rstudio.github.io/renv/).
-   A whole bunch of c++ libraries (documenting is a TODO - sorry!), most importantly related to GDAL

### Installation

1.  Install the package:

``` r
remotes::install_github("BioDT/uc-ces-recreation2")
```

2.  Download the data:

``` r
biodt.recreation::download_data()
```

### Usage

3.  Run the app:

``` r
biodt.recreation::run_app()
```

4.  Use the package in a script

``` r
library(terra)
library(biodt.recreation)

persona <- load_persona("path/to/my_persona.csv", "Running")
bbox <- ext(xmin, xmax, ymin, ymax)

layers <- compute_potential(persona, bbox)

plot(layers$Recreational_Potential)
```

<!-- prerequisites: gdal, a bunch of c++ libs..? -->

## For developers

### Quickstart for developers

Clone the repository

``` sh
git clone https://github.com/BioDT/uc-ces-recreation2
cd uc-ces-recreation2
```

In an R session, install the dependencies

``` r
renv::restore()
```

> [!N
> OTE] If this does not work, try removing `renv.lock` and `renv/` and doing `renv::init()`, followed by selecting (1) 'explicit' mode, followed by (2) re-load library.

Load the package (run this after making any changes!)

``` r
devtools::load_all()
```

Download the data

``` r
download_data()
```

Pull up the documentation for a function, e.g. `compute_potential`

``` r
?biodt.recreation::compute_potential
```

### NERC DataLabs

To do.

### Enabling pre-commit hooks

We recommend the use of [pre-commit hooks](https://pre-commit.com/), which help ensure that code that gets committed is 'ok'.
R-specific instructions can be found at [lorenzwalthert.github.io/precommit](https://lorenzwalthert.github.io/precommit/articles/precommit.html).

If you are happy for the `{precommit}` R package to handle everything, you can simply run the following in an R session in the repository root:

``` r
install.packages("precommit")
precommit::install_precommit()  # omit this if you already installed pre-commit
precommit::use_precommit()
```

Now, when you commit a bunch of hooks will run that will check various things.
**You may find that you need to fix something and attempt the commit again.**

You can run the hooks manually using

``` sh
pre-commit run --all-files
```

### Additional tools

If you're comfortable running things from the shell, the `scripts/` directory may be useful to you.
See [scripts/README.md](scripts/README.md) for further guidance.

### Testing the installed package

It is a good idea to frequently test a fresh installation of the package, rather than simply relying on `devtools::load_all`.

Create a fresh environment in a temporary directory

``` r
renv::init(bare = TRUE)
renv::install("devtools")
```

You can install from GitHub

``` r
remotes::install_github("BioDT/uc-ces-recreation2")
```

or locally

``` r
devtools::install("path/to/uc-ces-recreation2", dependencies = TRUE)
```

Download the data using

``` r
biodt.recreation::download_data()
```

Run the tests

``` r
renv::install("testthat")
testthat::test_package("biodt.recreation")
```

Check the app works...

``` r
biodt.recreation::run_app()
```

### Contributing guidelines

If you are interested in contributing, please take a quick look at [CONTRIBUTING.md](CONTRIBUTING.md).

## Contributors

-   Chris Andrews
-   Will Bolton
-   Joe Marsh Rossney @jmarshrossney
-   Simon Rolph
-   Maddalena Tigli

## Older versions

The code has gone through 3 major iterations.

-   2023 version, primarily developed by Will Bolton (<https://github.com/BioDT/uc-ces/tree/main/recreation_model>)
-   2024 version, primarily developed by Chris Andrews and Maddalena Tigli (<https://github.com/BioDT/uc-ces-recreation2/tree/2024-model>)
-   2025 version, primarily developed by Joe Marsh Rossney and Maddalena Tigli (this version)

## Acknowledgements

-   BioDT
-   SPEAK funding, and feedback from participants in this study

## Citation

$$TODO$$
