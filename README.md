# BioDT Recreation Potential model

- Introduction to BioDT, appropriate links to UKCEH and BioDT
- Recreational Potential is one half of the 'Cultural Ecosystem Services prototype Digital Twin' (CES pDT) developed by UKCEH.


## Usage


### Installation

```sh
git clone https://github.com/BioDT/uc-ces-recreation2
cd uc-ces-recreation2
```

You can install directly from GitHub, provided you have `devtools` installed,

```R
devtools::install_github("BioDT/uc-ces-recreation2")
```

### Use in scripts

```R
biodt.recreation::compute_potential(TODO)
```

### Running the app

```R
biodt.recreation::run_app()
```

If you prefer to run things from the shell, you can also run the app from the command line (bash shell required),

```sh
chmod +x run_app.sh
./run_app.sh
```

### Running the CLI

If you installed the package, you will need to copy the script from `path/to/biodt.recreation/cli/main.R`.

If you cloned the repository from GitHub, you will find the script in `uc-ces-recreation/inst/cli/main.R`.

Then

```R
Rscript main.R ARGS
```

For more details see the [README](inst/cli/README.md).


## Development

### Prerequisites

- Git
- R version 4.4.x
- [`renv`](https://rstudio.github.io/renv/), which you can install using `install.packages("renv")`
- A whole bunch of libraries - documenting is a TODO

### Getting started

1. Clone repository

```sh
git clone https://github.com/BioDT/uc-ces-recreation2
cd uc-ces-recreation2
```

2. Download data

To do

```R
devtools::load_all("path/to/uc-ces-recreation2")
```

## Repository Overview

### `R/`

This directory contains an implementation of the Recreational Potential model, bundled as an `R` package. Because all of the complicated, expensive manipulations are done ahead of time in the data pre-processing stage, there is remarkably little here!

The repository also contains an R Shiny app which enables users to visualise Recreational Potential values in Scotland, based on a customisable set of importance scores for 81 different items.
This was developed independently of the [official BioDT app](https://app.biodt.eu/app/biodtshiny), and was used in a 2025 study _\[todo: links when complete\]_.

A live instance of the Recreational Potential app is hosted at _\[todo: link to datalabs instance\]_.


### `inst/cli/`

This directory contains an R script that allows you to run the Recreational Potential model from the command line, providing the required inputs as arguments.

Further details can be found in [cli/README.md](cli/README.md).

### `data_production/`

This directory contains the `R` scripts used to transform geospatial data from multiple sources into a homogeneous spatial raster, and perform some computational expensive processing.

Further details can be found in [data_production/README.md](data/README.md).


## Contributing

If you are interested in contributing, please take a quick look at [CONTRIBUTING.md](CONTRIBUTING.md).

## Contributors

The code has gone through 3 major iterations.

- version 1 (2023), primarily developed by Will Bolton (https://github.com/BioDT/uc-ces/tree/main/recreation_model)
- version 2 (2024), primarily developed by Chris Andrews and Maddalena Tigli (https://github.com/BioDT/uc-ces-recreation2/tree/2024-model)
- version 3 (2025), primarily developed by Joe Marsh Rossney and Maddalena Tigli (this version)


## Acknowledgements

- BioDT
- SPEAK funding, and feedback from participants in this study
