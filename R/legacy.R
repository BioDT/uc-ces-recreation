# This should be deleted eventually, but I am curious to compare the speed
.one_hot_layer_old <- function(infile, outfile, feature_mapping) {
    layer <- terra::rast(infile)
    stopifnot(terra::nlyr(layer) == 1)

    sublayer_stack <- lapply(
        # NOTE: These names are integer values (Raster_Val column in config.csv)
        feature_mapping,
        function(i) {
            sublayer_i <- terra::ifel(layer == as.numeric(i), 1, NA)
            names(sublayer_i) <- names(feature_mapping)[i]
            return(sublayer_i)
        }
    )
    terra::writeRaster(
        terra::rast(sublayer_stack),
        outfile,
        datatype = "INT1U",
        overwrite = TRUE
    )
}

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

# Useless because `terra::buffer` calls the same `proximity` function as
# `terra::distance`
.compute_buffer <- function(infile, outfile) {
    raster <- terra::rast(infile)

    # TODO: remove crop and run somewhere with more memory
    # raster <- terra::crop(raster, terra::vect("data/Shapefiles/Bush/Bush.shp"))

    terra::buffer(
        raster,
        width = 500, # metres
        background = NA,
        filename = outfile,
        datatype = "INT2S" # So NA is represented properly TODO: replace with INT1S
    )
}

# A far less efficient way of computing the same buffer as above
# (well, 0 and 1 are inverted)
# But it has lower peak memory requirements since it is based on an operation
# over a window of finite extent
compute_buffer <- function(infile, outfile) {
    raster <- terra::rast(infile)

    # TODO: remove crop and run somewhere with more memory
    # raster <- terra::crop(raster, terra::vect("data/Shapefiles/Bush/Bush.shp"))

    circle <- terra::focalMat(raster, d = 500, type = "circle", fillNA = TRUE)
    circle[!is.na(circle)] <- 0

    terra::focal(
        raster,
        w = circle,
        fun = sum,
        na.rm = TRUE, # ignore NA in `fun`
        na.policy = "only", # only compute for NA cells - leave non-NA alone
        silent = FALSE,
        filename = outfile
    )
}

# `buffer` is a raster with values {0, 1, NA}
# Whether 1 corresponds to the feature or the buffer region depends on whether
# the buffer was computed using `terra::buffer` or `terra::focal`.
compute_distance_in_buffer <- function(infile, outfile) {
    buffer <- terra::rast(infile)
    terra::distance(
        buffer,
        target = 0, # NOTE: 1 for output of terra::buffer, 0 for output of terra::focal
        exclude = NA,
        unit = "m",
        method = "haversine",
        filename = outfile,
        datatype = "FLT4S"
    )
}

gauss_blur <- function(infile, outfile) {
    raster <- terra::rast(infile)

    # TODO: remove crop and run somewhere with more memory
    raster <- terra::crop(raster, terra::vect("data/Shapefiles/Bush/Bush.shp"))

    gauss <- terra::focalMat(raster, d = 100, type = "Gauss")
    raster <- terra::focal(
        raster,
        w = gauss,
        fun = sum,
        na.rm = TRUE,
        na.policy = "all",
        silent = FALSE,
        filename = tempfile(fileext = ".tif"),
        overwrite = TRUE
    )

    min_value <- min(terra::values(raster), na.rm = TRUE)
    max_value <- max(terra::values(raster), na.rm = TRUE)
    if (max_value == min_value) {
        message(paste("The data could not be rescaled to the interval [0, 1], because the smallest and largest value are the same number", max_value)) # nolint
    }

    terra::app(
        raster,
        fun = function(x) (x - min_value) / (max_value - min_value),
        filename = outfile
    )
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
