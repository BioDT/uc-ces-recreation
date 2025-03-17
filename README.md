# BioDT Recreation Potential model

- Introduction to BioDT, appropriate links to UKCEH and BioDT
- Recreational Potential is one half of the 'Cultural Ecosystem Services prototype Digital Twin' (CES pDT) developed by UKCEH.

## Repository Overview

### `data/`

This directory contains the `R` scripts used to transform geospatial data from multiple sources into a homogeneous spatial raster, and perform some computational expensive processing.

Further details can be found in [data/README.md](data/README.md).

### `model/`

This directory contains an implementation of the Recreational Potential model, bundled as an `R` package. Because all of the complicated, expensive manipulations are done ahead of time in the data pre-processing stage, there is remarkably little here!

Further details can be found in [data/README.md](data/README.md).

### `notebooks/`

This directory contains Quarto notebooks for testing, sanity checking and example usage are provided.

Further details can be found in [data/README.md](data/README.md).

### `shiny_app/`

The repository also contains an R Shiny app which enables users to visualise Recreational Potential values in Scotland, based on a customisable set of importance scores for 81 different items.
This was developed independently of the [official BioDT app](https://app.biodt.eu/app/biodtshiny), and was used in a 2025 study _\[todo: links when complete\]_.

A live instance of the Recreational Potential app is hosted at _\[todo: link to datalabs instance\]_.

Further details can be found in [data/README.md](data/README.md).

## Getting Started

1. Clone repository

```sh
git clone https://github.com/BioDT/uc-ces-recreation2
cd uc-ces-recreation2
```

2. Download data

To do

3. Make sure you have installed [`renv`](https://rstudio.github.io/renv/)

4. See any of the `README.md` files in the subdirectories listed above

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
