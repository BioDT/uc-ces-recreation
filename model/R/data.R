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



# -------------------------------------------------------------

#' @export
categorical_to_one_hot <- function(layer, feature_mapping) {
    stopifnot(terra::nlyr(layer) == 1)
    sublayer_stack <- lapply(
        # NOTE: These names are integer values (Raster_Val column in config.csv)
        names(feature_mapping),
        function(i) {
            sublayer_i <- terra::ifel(layer == as.numeric(i), 1, 0)
            # NOTE: feature_mapping[i] may be "feature_j" where j =\= i !
            # E.g. FIPS_N_Landform_2 has a 'Raster_Val' of 3, unfortunately
            names(sublayer_i) <- feature_mapping[i]
            return(sublayer_i)
        }
    )
    return(terra::rast(sublayer_stack))
}

#' Convert raster to int
#'
#' @export
to_int <- function(raster, tol = 1e-5) {
    # NOTE: see https://github.com/rspatial/terra/issues/763 for why
    # SpatRasters may be double-typed even when .tif is integer-typed

    values <- terra::values(raster)
    rounded_values <- round(values)

    # Throw an error if any values are further than 'tol' from the nearest int
    if (any(abs(values - rounded_values) > tol)) {
        stop("Raster contains non-integer values")
    }

    terra::values(raster) <- rounded_values

    return(raster)
}

#' NA to zero
#'
#' Map NA (not available / missing) to zero, keeping NaN as is
#'
#' @export
na_to_zero <- function(raster) {
    return(terra::ifel(is.na(raster) & !is.nan(raster), 0, raster))
}

#' Sum the layers of a SpatRaster
#'
#' @export
sum_layers <- function(raster) {
    return(terra::app(raster, sum))
}



#' Map distances to the unit interval
#'
#' Uses a logistic function to map positive distances \eqn{d}
#' to the unit interval \eqn{x \in [0, 1]}.
#'
#' \deqn{ x = \frac{\kappa + 1}{\kappa + \exp(\alpha d)} }
#'
#' @param x A raster
#' @param alpha Coefficient in the exponent
#' @param kappa A less important parameter
#'
#' @export
map_distance_to_unit_interval <- function(x, alpha, kappa) {
    # TODO: add link to paper, equation etc.
    return((kappa + 1) / (kappa + exp(alpha * x)))
}
