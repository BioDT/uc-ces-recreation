# File:       config.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation2
# License:    MIT
# Copyright:  2025 BioDT
# Author(s):  Joe Marsh Rossney

# NOTE: cannot use system.file in the top-level scope, or devtools::install
# will throw an error due to "hard coded paths". This *needs* to be wrapped in
# a function and only called within other functions!
get_default_config <- function() system.file("extdata", "config.csv", package = "biodt.recreation", mustWork = TRUE)

#' Load Config
#'
#' Load a model configuration from a CSV file.
#'
#' This function essentially calls `readr::read_csv` with `col_types` set to reflect the
#' expected columns in a model configuration. That is: four `character` columns for
#' `Component`, `Dataset`, `Name`, and `Description`, followed by one `integer` column
#' for `Raster_Val`. See `inst/extdata/config.csv` for an example of a valid configuration
#' file.
#'
#' @param config_path (`character`) Path to a CSV file containing the configuration.
#' If no path is given, the default configuration from `inst/extdata/config.csv` will be loaded.
#'
#' @returns A `data.frame` containing the configuration.
#'
#' @example inst/examples/load_config.R
#'
#' @export
load_config <- function(config_path = NULL) {
    if (is.null(config_path)) {
        config_path <- get_default_config()
    }
    column_spec <- readr::cols(
        Component = readr::col_character(),
        Dataset = readr::col_character(),
        Name = readr::col_character(),
        Description = readr::col_character(),
        Raster_Val = readr::col_integer()
    )
    loaded_config <- readr::read_csv(config_path, col_types = column_spec)

    return(loaded_config)
}

#' Get Feature Mappings
#'
#' Load mappings from features to raster values from a loaded configuration.
#'
#' Given a loaded configuration, this function returns a mapping from
#' features to the corresponding values in the raw raster file. These mappings
#' are furthermore grouped into datasets.
#'
#' @param config A loaded configuration.
#'
#' @returns A named list containing named lists, with the structure
#' \{layer_name : \{feature_name : raster_value\}\}
#'
#' @export
get_feature_mappings <- function(config) {
    # Group by layer, results in {layer_name : layer_config}
    config_by_layer <- split(config, as.factor(config[["Dataset"]]))

    # Generate mapping {layer_name : {feature_name: raster_value}}
    mappings <- lapply(
        config_by_layer, function(layer_config) {
            stats::setNames(as.numeric(layer_config[["Raster_Val"]]), layer_config[["Name"]])
        }
    )
    return(mappings)
}
