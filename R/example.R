#' Get Example Persona
#' @export
get_example_persona <- function() {
    load_persona(get_preset_persona_file(), "Hard_Recreationalist")
}

#' Get Example Bbox
#' @export
get_example_bbox <- function() {
    terra::ext(
        terra::vect(
            system.file("extdata", "shapefiles", "Bush", "Bush.shp",
                package = "biodt.recreation", mustWork = TRUE
            )
        )
    )
}

#' Get Example Data Dir
#' @export
get_example_data_dir <- function() {
    system.file("extdata", "rasters", "Bush",
        package = "biodt.recreation", mustWork = TRUE
    )
}
