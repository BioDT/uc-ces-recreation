# File:       data.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation2
# License:    MIT
# Copyright:  2025 BioDT
# Author(s):  Joe Marsh Rossney

.assert_valid_data_dir <- function(data_dir) {
    if (!dir.exists(data_dir)) {
        stop(paste0("Error: the directory ", data_dir, " does not exist"))
    }

    if (!file.access(data_dir, 4) == 0) {
        stop(paste0("Error: the directory ", data_dir, " is not readable"))
    }

    required_files <- c(
        "SLSRA.tif",
        "FIPS_N.tif",
        "FIPS_I.tif",
        "Water.tif"
    )
    missing_files <- required_files[!required_files %in% list.files(data_dir)]

    if (length(missing_files) > 0) {
        stop(paste0("Error: the directory ", data_dir, " is missing the following required files: ", paste(missing_files, collapse = ", "))) # nolint
    }

    # TODO: check names of rasters
}

#' Get Default Data Directory
#'
#' Get the path to the default data directory containing the input rasters.
#'
#' @export
get_default_data_dir <- function() system.file("extdata", package = "biodt.recreation", mustWork = TRUE)

#' Load Raster
#'
#' Load a `SpatRaster` from a file, optionally cropping it to a given area.
#'
#' This function is a convenience wrapped around [terra::rast] which also
#' crops the raster to an area (if given) using [terra::crop], and finally
#' masks it using [terra::mask] if `area` is a `SpatVector`.
#'
#' @param raster_path Path to a file from which to load the raster.
#' @param area A `SpatExtent` or another valid object (such as a `SpatVector`)
#' with which to crop the raster.
#'
#' @returns The loaded and cropped `SpatRaster`.
#'
#' @export
load_raster <- function(raster_path, area = NULL) {
    # Lazy load raster from file
    raster <- terra::rast(raster_path)

    if (is.null(area)) {
        return(raster)
    }

    # Crop using either a shapefile or SpatExtent
    raster <- terra::crop(raster, area)

    # If crop_area is a vector we also need to mask, since
    # terra::crop only restricts to the bounding box of the vector
    if (inherits(area, "SpatVector")) {
        raster <- terra::mask(raster, area)
    }

    return(raster)
}
