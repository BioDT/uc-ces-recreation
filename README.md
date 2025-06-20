# The Recreation Potential Model for Scotland

This repository contains an implementation of the Recreational Potential Model for Scotland, developed by the [UK Centre for Ecology & Hydrology](https://www.ceh.ac.uk/) as part of the [BioDT project](https://biodt.eu/).

Recreational Potential is one half of the 'Cultural Ecosystem Services prototype Digital Twin' (CES pDT).
The other half is a Biodiversity model which can be found in the [uc-ces](https://github.com/BioDT/uc-ces) repository.

Associated documentation and technical reports are available at [https://biodt.github.io/ces-recreation-reports](https://biodt.github.io/ces-recreation-reports).

## Overview

The model itself is bundled as an `R` package called `biodt.recreation`.
It can be run in an interactive `R` session, as a command-line script, or through an R Shiny app which is distributed as part of the package.

### R Package

The `R/` directory contains the source code for functions provided by the package.

The package may be installed using standard tools, after which these functions are available under the `biodt.recreation` namespace.

```r
> persona <- biodt.recreation::load_persona("path/to/personas.csv", name = "Running")
> bbox <- terra::ext(xmin, xmax, ymin, ymax)  # must be within Scotland!
> layers <- biodt.recreation::compute_potential(persona, bbox)
> terra::plot(layers$Recreational_Potential)
```

### App

The package comes with an R Shiny app which enables users to visualise Recreational Potential values.
This was developed independently from the [official BioDT app](https://app.biodt.eu/app/biodtshiny), and serves a different purpose.

![app_screenshot](https://github.com/user-attachments/assets/f3fd116f-552b-48a3-8047-058c175d83d0)


### Command-line interface

The directory `inst/scripts/cli/` contains an R script that allows you to run the Recreational Potential model from the command line, providing the required inputs as arguments.

There is also a singularity container definition file which builds a container that becomes a drop-in replacement for the script.

Further details can be found in [inst/scripts/cli/README.md](inst/scripts/cli/README.md).

### Data production script

The directory `inst/scripts/data_production/` contains an R script that produces the input data for the Recreational Potential model from some pre-existing raster files.
Unfortunately at this point we do not have the full provenance of this data, but we expect to figure this out and complete the data processing pipeline in the near future.
There is also a singularity container.

Further details can be found in [inst/scripts/data_production/README.md](inst/scripts/data_production/README.md).

## Instructions for users

### Prerequisites

The Recreational Potential model has been developed on recent (2025) versions of `R` - specifically versions 4.4.2 up to 4.5.0. We cannot guarantee that it will work for versions of `R` outside of this range.

The following command tells you what version is currently active:

```r
# Ideally this should be between 4.4.2 and 4.5.0
R.version.string
```

Certain C++ libraries are required for the model to work, most importantly related to GDAL. See the [`terra` documentation](https://rspatial.github.io/terra/) for guidance.

It is recommended to perform the following steps using an R envirnoment managed by [`renv`](https://rstudio.github.io/renv/).

### Installation

Ensure you have either `remotes` or `devtools` installed (using e.g. `install.packages` or `renv::install`).

```r
install.packages("remotes")
```

Now install the package itself.

```r
remotes::install_github("BioDT/uc-ces-recreation")
```

Next, you will need to download the input data. The total size is over 2GB, so it is important to set the `timeout` option to something generous.

```r
options(timeout=1200)
biodt.recreation::download_data()
```

### Usage

To run the app, do the following:

``` r
biodt.recreation::run_app()
```

Here is an example that calculates and plots Recreational Potential.
It is assumed that `path/to/my_persona.csv` points to a persona `.csv` file containing a persona called "Running", and that `xmin, xmax, ymin, ymax` define a valid bounding box in Scotland.

``` r
library(biodt.recreation)

persona <- load_persona("path/to/my_persona.csv", "Running")
bbox <- terra::ext(xmin, xmax, ymin, ymax)

layers <- compute_potential(persona, bbox)

terra::plot(layers$Recreational_Potential)
```

To pull up the documentation for a function, e.g. `compute_potential`, use the `?` operator:

``` r
?biodt.recreation::compute_potential
```


## Instructions for developers

### Quickstart for developers

Clone the repository

``` sh
git clone https://github.com/BioDT/uc-ces-recreation
cd uc-ces-recreation
```

In an R session, install the dependencies

``` r
renv::restore()
```

> [!NOTE] If this does not work, try removing `renv.lock` and `renv/` and doing `renv::init()`, followed by selecting (1) 'explicit' mode, followed by (2) re-load library.

Load the package (run this after making any changes!):

``` r
devtools::load_all()
```

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

If you're comfortable running things from the terminal, the `dev/` directory may be useful to you.
See [dev/README.md](dev/README.md) for further guidance.

### Testing the installed package

It is a good idea to frequently test a fresh installation of the package, rather than simply relying on `devtools::load_all`.

Create a fresh environment in a temporary directory

``` r
renv::init(bare = TRUE)
renv::install("devtools")
```

You can install from GitHub,

``` r
remotes::install_github("BioDT/uc-ces-recreation")
```

or locally,

``` r
devtools::install("path/to/uc-ces-recreation", dependencies = TRUE)
```

Download the data using

``` r
biodt.recreation::download_data()
```

Run the tests:

``` r
renv::install("testthat")
testthat::test_package("biodt.recreation")
```

Check the app works:

``` r
biodt.recreation::run_app()
```

### Contributing guidelines

If you are interested in contributing, please take a quick look at [CONTRIBUTING.md](CONTRIBUTING.md).

## Previous versions

The code has gone through 3 major iterations.

- 2023 version: https://github.com/BioDT/uc-ces/tree/main/recreation_model
- 2024 version: https://github.com/BioDT/uc-ces-recreation/tree/2024-model
- 2025 version: https://github.com/BioDT/uc-ces-recreation

## Contributors

The following people contributed directly to the code:

- Will Bolton (2023)
- Chris Andrews (2024)
- Simon Rolph (2024)
- Maddalena Tigli (2024,25)
- Joe Marsh Rossney (2025)


## Acknowledgements

Funding for BioDT came from the European Union’s Horizon Europe Research and Innovation Programme under grant agreement No 101057437 (BioDT project, https://doi.org/10.3030/101057437)

Funding for SPEAK came from the Natural Environment Research Council – Growing Shoots Partnership and application co-creation bursary. NE/Y005805/1 _Growing Shoots.

We are very grateful to all the participants of the SPEAK project which this output is based on including.

## Citation

Biblatex citation:

```bib
@Software{ukceh2025,
  author = {Marsh Rossney, Joe and Tigli, Maddalena and Andrews, Chris and Rolph, Simon and Bolton, Will},
  date   = {2025-06-30},
  doi    = {10.5281/zenodo.15705544},
  title  = {The {BioDT} Recreational Potential Model for {Scotland}, v1.0},
  url    = {https://github.com/BioDT/uc-ces-recreation},
}
```

For attribution, please cite this work as:

> J. Marsh Rossney, M. Tigli, C. Andrews, S. Rolph, and W. Bolton. 2025. “The BioDT Recreational Potential Model for Scotland, v1.0.” https://doi.org/10.5281/zenodo.15705544.
