# BioDT Recreation Potential model

- Introduction to BioDT, appropriate links to UKCEH and BioDT
- Recreational Potential is one half of the 'Cultural Ecosystem Services prototype Digital Twin' (CES pDT) developed by UKCEH.


## Overview

### Package

This repository contains an implementation of the Recreational Potential model developed by \[CITATION\] as an `R` package.

```R
> persona <- load_persona("path/to/personas.csv", name = "Running")
> bbox <- terra::ext(xmin, xmax, ymin, ymax)  # must be within Scotland!
> layers <- compute_potential(persona, bbox)
> names(layers)
[1] "SLSRA"                  "FIPS_N"                 "FIPS_I"                
[4] "Water"                  "Recreational_Potential"
> plot(layers$Recreational_Potential)
```

\[To do: add image\]

### App

The package comes bundled with an R Shiny app which enables users to visualise Recreational Potential values in Scotland, based on a customisable set of importance scores for 81 different items.
This was developed independently of the [official BioDT app](https://app.biodt.eu/app/biodtshiny), and was used in a 2025 study _\[todo: links when complete\]_.

\[To do: add image\]

A live instance of the Recreational Potential app is hosted at _\[todo: link to datalabs instance\]_.

### Command-line interface

The directory `inst/cli/` contains an R script that allows you to run the Recreational Potential model from the command line, providing the required inputs as arguments.

Further details can be found in [inst/cli/README.md](inst/cli/README.md).

### Data production script

\[To do\]


## Quickstart for users

### Prerequisites

- R version 4.4.x
- Ensure you have either `remotes` or `devtools` installed (using e.g. `install.packages` or `renv::install`)
- It is recommended to perform the following steps using an R envirnoment managed by [`renv`](https://rstudio.github.io/renv/).
- A whole bunch of c++ libraries (documenting is a TODO - sorry!), most importantly related to GDAL


### Installation

1. Install the package:

```R
remotes::install_github("BioDT/uc-ces-recreation2")
```

2. Download the data:

```R
biodt.recreation::download_data()
```

### Usage

3. Run the app:

```R
biodt.recreation::run_app()
```

4. Use the package in a script

```R
library(terra)
library(biodt.recreation)

persona <- load_persona("path/to/my_persona.csv", "Running")
bbox <- ext(xmin, xmax, ymin, ymax)

layers <- compute_potential(persona, bbox)

plot(layers$Recreational_Potential)
```

<!-- prerequisites: gdal, a bunch of c++ libs..? -->

## Quickstart for developers

Clone the repository

```sh
git clone https://github.com/BioDT/uc-ces-recreation2
cd uc-ces-recreation2
```

In an R session, install the dependencies

```R
renv::restore()
```

> [!NOTE]
> If this does not work, try removing `renv.lock` and `renv/` and doing `renv::init()`, followed by selecting (1) 'explicit' mode, followed by (2) re-load library.

Load the package (run this after making any changes!)

```R
devtools::load_all()
```

Download the data

```R
download_data()
```

Pull up the documentation for a function, e.g. `compute_potential`

```R
?biodt.recreation::compute_potential
```

For more detailed guidance, see [CONTRIBUTING.md](CONTRIBUTING.md).


## Contributing

If you are interested in contributing, please take a quick look at [CONTRIBUTING.md](CONTRIBUTING.md).


## Contributors

The code has gone through 3 major iterations.

- 2023 version, primarily developed by Will Bolton (https://github.com/BioDT/uc-ces/tree/main/recreation_model)
- 2024 version, primarily developed by Chris Andrews and Maddalena Tigli (https://github.com/BioDT/uc-ces-recreation2/tree/2024-model)
- 2025 version, primarily developed by Joe Marsh Rossney and Maddalena Tigli (this version)


## Acknowledgements

- BioDT
- SPEAK funding, and feedback from participants in this study
