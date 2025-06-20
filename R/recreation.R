# File:       recreation.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation
# License:    MIT
# Copyright:  2025 BioDT and the UK Centre for Ecology & Hydrology
# Author(s):  Joe Marsh Rossney

assert_valid_component <- function(component) {
    valid_components <- c("SLSRA", "FIPS_N", "FIPS_I", "Water")
    if (!component %in% valid_components) {
        stop(paste("Error:", component, "is not a valid component; should be one of", valid_components)) # nolint
    }
}

#' Compute Component
#'
#' Compute a single component of the Recreational Potential.
#'
#' This function computes one _component_, \eqn{p_i}, of the Recreational Potential.
#' This is is one of
#' * SLSRA
#' * FIPS_N
#' * FIPS_I
#' * Water
#'
#' A component is simply a pixel-wise summation of all of the layers/items/features,
#' \eqn{f_{i,j}}, (most of which are either 1/present or 0/absent),
#' weighted by the corresponding persona scores, \eqn{s_{i,j}},
#'
#' \deqn{ p_i(x, y) = \sum_{j=1}^{n_i} s_{i,j} f_{i,j}(x, y) }
#'
#' @param component The name of the component to compute (one of "SLSRA", "FIPS_N", "FIPS_I", "Water").
#' @param persona A named vector containing the persona scores (for all components).
#' @param data_dir Path to the directory containing the rasters.
#' @param bbox An optional bounding box for cropping.
#' @param skip_checks Pass `TRUE` to skip checks of the validity of the inputs.
#' @returns A single-layered `SpatRaster` which is the contribution to the Recreational Potential from this component.
#'
#' @example inst/examples/compute_component.R
#'
#' @export
compute_component <- function(component, persona, bbox, data_dir = NULL, skip_checks = FALSE) {
    if (is.null(data_dir)) {
        data_dir <- get_data_dir()
    }
    if (!skip_checks) {
        assert_valid_component(component)
        assert_valid_data_dir(data_dir)
        assert_valid_bbox(bbox)
    }

    raster <- load_raster(
        file.path(data_dir, paste0(component, ".tif")),
        bbox
    )
    scores <- persona[names(raster)]
    result <- terra::app(raster, function(features) {
        sum(scores * features, na.rm = TRUE)
    })
    return(result)
}

#' Compute SLSRA Component
#'
#' Compute the SLSRA ("Suitability of Land to Support Recreational Activity")
#' component of the Recreational Potential. This is a convenience wrapper around
#' [biodt.recreation::compute_component] with the argument `component = "SLSRA"`.
#'
#' @param ... Parameters passed straight to [biodt.recreation::compute_component]
#' @export
compute_slsra <- function(...) compute_component("SLSRA", ...)

#' Compute FIPS_N Component
#'
#' Compute the FIPS_N ("Natural Features Impacting Potential Services") component
#' of the Recreational Potential. This is a convenience wrapper around
#' [biodt.recreation::compute_component] with the argument `component = "FIPS_N"`.
#'
#' @param ... Parameters passed straight to [biodt.recreation::compute_component]
#' @export
compute_fips_n <- function(...) compute_component("FIPS_N", ...)

#' Compute FIPS_I Component
#'
#' Compute the FIPS_I ("Infrastructure Features Impacting Potential Services")
#' component of the Recreational Potential. This is a convenience wrapper around
#' [biodt.recreation::compute_component] with the argument `component = "FIPS_I"`.
#'
#' @param ... Parameters passed straight to [biodt.recreation::compute_component]
#' @export
compute_fips_i <- function(...) compute_component("FIPS_I", ...)

#' Compute FIPS_I Component
#'
#' Compute the Water component of the Recreational Potential. This is a convenience
#' wrapper around [biodt.recreation::compute_component] with the argument
#' `component = "Water"`.
#'
#' @param ... Parameters passed straight to [biodt.recreation::compute_component]
#' @export
compute_water <- function(...) compute_component("Water", ...)

#' Rescale to Unit Interval
#'
#' Rescale a SpatRaster to the interval \[0, 1\] using a data-dependent affine
#' (shift-and-rescale) transformation.
#'
#' Given a `SpatRaster` with layers \eqn{v_i(x, y) \in \mathbb{R}}, the transformation
#' implemented is given by
#'
#' \deqn{ \hat{v}_i(x, y) = \frac{v_i(x, y) - \min_{x,y}(v_i)}{\max_{x,y}(v_i) - \min_{x,y}(v_i)} \in [0, 1]}
#'
#' I.e. every layer will be shifted and rescaled such that the layer minimum and maximum
#' are 0 and 1 respectively.
#'
#' `NA` entries are silently ignored. A _message_ (not an error) will be raised if
#' the layer cannot be rescaled due to being single-valued.
#'
#' @param raster The `SpatRaster` to be transformed.
#' @returns A rescaled `SpatRaster` of the same dimensions as the input.
#'
#' @export
rescale_to_unit_interval <- function(raster) {
    min_value <- min(terra::values(raster), na.rm = TRUE)
    max_value <- max(terra::values(raster), na.rm = TRUE)

    if (max_value == min_value) {
        message(paste("The data could not be rescaled to the interval [0, 1], because the smallest and largest value are the same number", max_value)) # nolint
    }

    result <- (raster - min_value) / (max_value - min_value)

    return(result)
}

#' Compute Recreational Potential
#'
#' Compute all four components and aggregate into the Recreational Potential value.
#'
#' The Recreational Potential value, \eqn{\hat{P}(x, y)}, is given by a normalised sum over
#' the four normalised components. That is,
#'
#' \deqn{ P(x, y) = \sum_{i=1}^{4}  \hat{p}_i(x, y) }
#'
#' where the hat denotes values that have been rescaled to the unit interval
#' using a data-dependent shift-and-rescale
#'
#' \deqn{ \hat{v}(x, y) = \frac{v(x, y) - \min_{x,y}(v)}{\max_{x,y}(v) - \min_{x,y}(v)} }
#'
#' @param persona A named vector containing the persona scores.
#' @param data_dir Path to the directory containing the rasters.
#' @param bbox An optional bounding box for cropping.
#' @returns A `SpatRaster` with five layers: the four components and the Recreational
#' Potential. All five layers are normalised to the unit interval \[0, 1\].
#'
#' @seealso
#' [biodt.recreation::compute_component] used to compute each component.
#' [biodt.recreation::rescale_to_unit_interval] performs the normalisation.
#'
#' @example inst/examples/compute_potential.R
#'
#' @export
compute_potential <- function(persona, bbox, data_dir = NULL) {
    if (is.null(data_dir)) {
        data_dir <- get_data_dir()
    }
    # Perform checks once here, and skip them in the individual components
    assert_valid_data_dir(data_dir)
    assert_valid_bbox(bbox)

    slsra <- compute_component("SLSRA", persona, bbox, data_dir, skip_checks = TRUE) |>
        rescale_to_unit_interval()
    fips_n <- compute_component("FIPS_N", persona, bbox, data_dir, skip_checks = TRUE) |>
        rescale_to_unit_interval()
    fips_i <- compute_component("FIPS_I", persona, bbox, data_dir, skip_checks = TRUE) |>
        rescale_to_unit_interval()
    water <- compute_component("Water", persona, bbox, data_dir, skip_checks = TRUE) |>
        rescale_to_unit_interval()

    total <- sum(slsra, fips_n, fips_i, water, na.rm = TRUE) |>
        rescale_to_unit_interval()

    layers <- c(slsra, fips_n, fips_i, water, total)
    names(layers) <- c("SLSRA", "FIPS_N", "FIPS_I", "Water", "Recreational_Potential")

    return(layers)
}
