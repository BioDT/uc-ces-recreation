#' Compute a single component
#'
#' @export
compute_component <- function(raster, persona) {
    scores <- persona[names(raster)]
    result <- terra::app(raster, function(features) {
        sum(scores * features, na.rm = TRUE)
    })
    return(result)
}

#' Compute Recreational Potential
#'
#' @export
compute_potential <- function(persona, raster_dir = NULL, bbox = NULL) {
    if (is.null(raster_dir)) {
        raster_dir <- get_raster_dir()
    }

    # Up-front check that raster_dir exists, is readable, contains required files
    .assert_valid_raster_dir(raster_dir)

    slsra <- file.path(raster_dir, "SLSRA.tif") |>
        load_raster(bbox) |>
        compute_component(persona) |>
        rescale_to_unit_interval()

    fips_n <- file.path(raster_dir, "FIPS_N.tif") |>
        load_raster(bbox) |>
        compute_component(persona) |>
        rescale_to_unit_interval()

    fips_i <- file.path(raster_dir, "FIPS_I.tif") |>
        load_raster(bbox) |>
        compute_component(persona) |>
        rescale_to_unit_interval()

    water <- file.path(raster_dir, "Water.tif") |>
        load_raster(bbox) |>
        compute_component(persona) |>
        rescale_to_unit_interval()

    total <- rescale_to_unit_interval(sum(slsra, fips_n, fips_i, water, na.rm = TRUE))

    layers <- c(slsra, fips_n, fips_i, water, total)
    names(layers) <- c("SLSRA", "FIPS_N", "FIPS_I", "Water", "Recreational_Potential")

    return(layers)
}
