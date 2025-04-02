.feature_mappings <- get_feature_mappings(load_config())


get_files <- function(data_dir) {
    # Generate a mapping { layer : file_path }
    file_paths <- lapply(
        list.files(path = data_dir, pattern = "\\.tif$", recursive = TRUE),
        function(file_) file.path(data_dir, file_)
    )
    file_stems <- lapply(
        file_paths,
        function(path) tools::file_path_sans_ext(basename(path))
    )
    files <- setNames(file_paths, file_stems)

    return(files)
}

quantise_slope <- function(layer) {
    # Quantise the slope values
    # NOTE: I do not know the origin of these intervals
    slope_rcl <- data.matrix(data.frame(
        lower_bound = c(0, 1.72, 2.86, 5.71, 11.31, 16.7),
        upper_bound = c(1.72, 2.86, 5.71, 11.31, 16.7, Inf),
        mapped_to = c(1, 2, 3, 4, 5, 6)
    ))
    return(terra::classify(layer, rcl = slope_rcl))
}

reproject_layer <- function(infile, outfile) {
    if (basename(infile) == "FIPS_N_Slope.tif") {
        layer <- terra::rast(infile) |> quantise_slope()
    } else {
        layer <- terra::rast(infile)
    }

    onto <- terra::rast(
        crs = "EPSG:27700",
        res = c(20, 20),
        ext = terra::ext(-10000, 660000, 460000, 1220000) # xmin, xmax, ymin, ymax
    )

    terra::project(
        layer,
        onto,
        method = "near",
        filename = outfile,
        datatype = "INT1U",
        threads = TRUE,
        overwrite = TRUE
    )
}

one_hot_layer <- function(infile, outfile, feature_mapping) {
    layer <- terra::rast(infile)
    stopifnot(terra::nlyr(layer) == 1)

    one_hot_pixel <- function(x) {
        out <- matrix(0, nrow = length(x), ncol = length(feature_mapping))
        for (i in seq_along(feature_mapping)) {
            out[, i] <- ifelse(x == as.numeric(feature_mapping[i]), 1, NA)
        }
        return(out)
    }

    layer <- terra::lapp(
        layer,
        fun = one_hot_pixel,
        filename = outfile,
        overwrite = TRUE,
        wopt = list(
            names = names(feature_mapping),
            datatype = "INT1U"
        )
    )
}

# Straight up application of `terra::distance` to the raster (no buffer)
compute_distance <- function(infile, outfile) {
    raster <- terra::rast(infile)
    # TODO: remove crop and run somewhere with more memory
    raster <- terra::crop(raster, terra::vect("data/Shapefiles/Bush/Bush.shp"))
    terra::distance(
        raster,
        target = NA, # targets everything excluding the features (v expensive!)
        unit = "m",
        method = "haversine",
        filename = outfile,
        datatype = "FLT4S"
    )
}

map_distance_to_unit <- function(infile, outfile) {
    logistic_func <- function(x, kappa = 6, alpha = 0.01011) {
        (kappa + 1) / (kappa + exp(alpha * x))
    }
    raster <- terra::rast(infile)
    terra::app(
        raster,
        fun = logistic_func,
        filename = outfile
        # NOTE: datatype inferred from raster - cannot be changed
    )
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
