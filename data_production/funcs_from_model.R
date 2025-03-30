# NOTE: these functions are either unused or duplicated in the data/ directory
# containing the actual data production scripts. I need to decide whether those
# scripts should load from the main package, or be standalone.

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
na_to_zero <- function(raster) {
    return(terra::ifel(is.na(raster) & !is.nan(raster), 0, raster))
}

#' Sum the layers of a SpatRaster
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
map_distance_to_unit_interval <- function(x, alpha, kappa) {
    # TODO: add link to paper, equation etc.
    return((kappa + 1) / (kappa + exp(alpha * x)))
}
