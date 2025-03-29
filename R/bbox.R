# File:       bbox.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation2
# License:    MIT
# Copyright:  2025 BioDT
# Author(s):  Joe Marsh Rossney

get_scot_boundaries <- function() {
    terra::vect(
        system.file("extdata", "Scotland", "boundaries.shp", package = "biodt.recreation", mustWork = TRUE)
    )
}

.assert_bbox_intersects_scot <- function(bbox, warn_if_not_within = FALSE) {
    scotland <- get_scot_boundaries()
    if (!terra::relate(bbox, scotland, "intersects")) {
        stop(paste(
            "The area specified does not contain any of Scotland's land surface.",
            "Please specify a different bounding box"
        ))
    }
    if (warn_if_not_within) {
        if (!terra::relate(bbox, scotland, "within")) {
            warning("Part of the bounding box is outside Scotland's land surface.")
        }
    }
}

.assert_bbox_is_valid_size <- function(bbox, min_area = 1e4, max_area = 1e9) {
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

#' Assert Valid Bbox
#'
#' Asserts that a given bounding box (bbox) is valid from the perspective of
#' calculating Recreational Potential. If it is not, an error is raised.
#'
#' There are currently two tests:
#' * Test 1: Bbox includes part of Scotland's land surface.
#' * Test 2: Bbox is a valid size.
#'
#' Test 1 tests whether the given area _intersects_ with the boundaries of
#' Scotland's land surface, using [terra::relate] with `relation = "intersects"`.
#' This also works when `bbox` is a `SpatVector` defining a more complex geometry
#' than a simple bounding box. It is optional to also test whether any part of the
#' bbox falls outside of the valid area, and print a warning message if so.
#' This calculation is more expensive so is switched off by default.
#'
#' Test 2 raises an error if the bbox has an area smaller than `min_area` or
#' larger than `max_area`.
#'
#' @param bbox A `SpatExtent` defining the bbox.
#' @param min_area The minimum allowable area in meters.
#' @param max_area The maximum allowable area in meters.
#' @param warn_if_not_within A flag to indicate whether to perform the additional check.
#'
#' @keywords internal
#' @export
assert_valid_bbox <- function(bbox, min_area = 1e4, max_area = 1e9, warn_if_not_within = FALSE) {
    .assert_bbox_intersects_scot(bbox, warn_if_not_within)
    .assert_bbox_is_valid_size(bbox, min_area, max_area)
}

#' Is Valid Bbox
#' 
#' Alternative to [biodt.recreation::assert_valid_bbox] that returns `TRUE`
#' or `FALSE` depending on whether the conditions are met or not.
#'
#' @seealso [biodt.recreation::assert_valid_bbox] the underlying function.
#' @seealso [biodt.recreation::assert_to_bool] the wrapper.
#' @keywords internal
#' @export
is_valid_bbox <- function(...) {
    assert_to_bool(assert_valid_bbox)(...)
}

#' Check Valid Bbox
#' 
#' Alternative to [biodt.recreation::assert_valid_bbox] that returns either 
#' `TRUE` or an instance of `simpleError` depending on whether the conditions
#' are met or not.
#'
#' @seealso [biodt.recreation::assert_valid_bbox] the underlying function.
#' @seealso [biodt.recreation::errors_as_messages] the wrapper.
#' @keywords internal
#' @export
check_valid_bbox <- function(...) {
    capture_messages(errors_as_messages(assert_valid_bbox))(...)
}
