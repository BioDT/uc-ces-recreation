# NOTE: cannot use system.file in the top-level scope, or devtools::install
# will throw an error due to "hard coded paths". This *needs* to be wrapped in
# a function and only called within other functions!
get_default_config <- function() system.file("extdata", "config.csv", package = "model", mustWork = TRUE)

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

#' @export
get_feature_mappings <- function(config) {
    # Group by layer, results in {layer_name : layer_config}
    config_by_layer <- split(config, as.factor(config[["Dataset"]]))

    # Generate mapping {layer_name : {feature_name: raster_value}}
    mappings <- lapply(
        config_by_layer, function(layer_config) {
            setNames(as.numeric(layer_config[["Raster_Val"]]), layer_config[["Name"]])
        }
    )
    return(mappings)
}
