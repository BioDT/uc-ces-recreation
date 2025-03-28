# File:       data.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation2
# License:    MIT
# Copyright:  2025 BioDT
# Author(s):  Joe Marsh Rossney

get_scotland_boundaries <- function() {
    terra::vect(
        system.file("extdata", "Scotland", "boundaries.shp", package = "biodt.recreation", mustWork = TRUE)
    )
}

#' Get Default Data Directory
#'
#' Get the path to the default data directory containing the input rasters.
#'
#' @export
get_default_data_dir <- function() system.file("extdata", package = "biodt.recreation", mustWork = TRUE)

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

#' Assert Bbox Intersects Scotland
#'
#' Asserts that a given bbox includes part of Scotland's land surface, meaning the
#' Recreational Potential can be computed. If it does not, an error is raised.
#'
#' The test performed is whether the given area _intersects_ with the boundaries
#' of Scotland's land surface, using [terra::relate] with `relation = "intersects"`.
#' This also works when `bbox` is a `SpatVector` defining a more complex geometry
#' than a simple bounding box.
#'
#' It is optional to also test whether any part of the bbox falls outside of the valid
#' area, and print a warning message if so. This calculation is more expensive so is
#' switched off by default.
#'
#' @param bbox A `SpatExtent` defining the bbox (or a `SpatVector`).
#' @param warn_if_not_within A flag to indicate whether to perform the additional check.
#'
#' @export
assert_bbox_intersects_scotland <- function(bbox, warn_if_not_within = FALSE) {
    scotland_boundaries <- get_scotland_boundaries()
    if (!terra::relate(bbox, scotland_boundaries, "intersects")) {
        stop(paste(
            "The area specified does not contain any of Scotland's land surface.",
            "Please specify a different bounding box"
        ))
    }
    if (warn_if_not_within) {
        if (!terra::relate(bbox, scotland_boundaries, "within")) {
            warning("Part of the bounding box is outside Scotland's land surface.")
        }
    }
}

check_bbox_intersects_scotland <- function(...) {
    assert_to_bool(assert_bbox_intersects_scotland)(...)
}

#' Assert Bbox is a Valid Size
#'
#' Raise an error if the given bounding box has an area smaller than
#' `min_area` or larger than `max_area`.
#'
#' @param bbox A `SpatExtent` defining the bbox.
#' @param min_area The minimum allowable area in meters.
#' @param max_area The maximum allowable area in meters.
#'
#' @export
assert_bbox_is_valid_size <- function(bbox, min_area = 1e4, max_area = 1e9) {
    if (is.null(bbox)) {
        stop("No area has been selected. Please select an area.")
    }
    area <- (terra::xmax(bbox) - terra::xmin(bbox)) * (terra::ymax(bbox) - terra::ymin(bbox))
    if (area > max_area) {
        stop(paste(
            "The area specified is too large to be computed at this time",
            "(", sprintf("%.1e", area), ">", max_area, " m^2 ).",
            "Please specify a smaller area."
        ))
    }
    if (area < min_area) {
        stop(paste(
            "The area specified is too small",
            "(", round(area), "<", min_area, " m^2 ).",
            "Please specify a larger area."
        ))
    }
    message(paste("Selected an area of", sprintf("%.1e", area), "m^2 ."))
}

check_bbox_is_valid_size <- function(...) {
    assert_to_bool(assert_bbox_is_valid_size)(...)
}


check_valid_bbox <- function(bbox, min_area = 1e4, max_area = 1e9) {
    intersects_scot <- check_bbox_intersects_scotland(bbox)
    valid_size <- check_bbox_is_valid_size(bbox, min_area, max_area)
    return(valid_size && intersects_scot)
}

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
