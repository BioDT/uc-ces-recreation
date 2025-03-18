#' @export
get_raster_dir <- function() system.file("extdata", package = "model", mustWork = TRUE)

.assert_valid_raster_dir <- function(raster_dir) {
    if (!dir.exists(raster_dir)) {
        stop(paste0("Error: the directory ", raster_dir, " does not exist"))
    }

    if (!file.access(raster_dir, 4) == 0) {
        stop(paste0("Error: the directory ", raster_dir, " is not readable"))
    }

    required_files <- c(
        "SLSRA.tif",
        "FIPS_N.tif",
        "FIPS_I.tif",
        "Water.tif"
    )
    missing_files <- required_files[!required_files %in% list.files(raster_dir)]

    if (length(missing_files) > 0) {
        stop(paste0("Error: the directory ", raster_dir, " is missing the following required files: ", paste(missing_files, collapse = ", "))) # nolint
    }

    # TODO: check names of rasters
}


#' Load a cropped raster
#'
#' @description
#' Load a cropped raster from a file
#'
#' @details
#' Details...
#'
#' @param raster_path `character` Path to a raster file to load
#' @param crop_area A SpatExtent or another object with a SpatExtent
#'
#' @examples
#' load_raster("path/to/raster.tif", terra::vect("path/to/shapefile.shp"))
#' load_raster("path/to.raster.tif", terra::ext(xmin, xmax, ymin, ymax))
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

#' Rescale a SpatRaster to [0, 1]
#'
#' Uses an affine transformation
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
