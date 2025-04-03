# File:       data_production.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation2
# License:    MIT
# Copyright:  2025 BioDT
# Author(s):  Joe Marsh Rossney

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Reprojection                              #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

#' Quantise Slope
#'
#' Takes a raster of absolute gradients and quantise them into 6 categories
#' according to their steepness.
#'
#' More generally, this function takes a non-negative, continous-valued raster
#' and uses [terra::classify] to create an integer-valued raster with values
#' `{1, 2, 3, 4, 5, 6}` using the following intervals:
#'
#' \deqn{ x_{out} = \begin{cases}
#' 1 & 0 \leq x_{in} < 1.72 \\
#' 2 & 1.72 \leq x_{in} < 2.86 \\
#' 3 & 2.86 \leq x_{in} < 5.71 \\
#' 4 & 5.71 \leq x_{in} < 11.31 \\
#' 5 & 11.31 \leq x_{in} < 16.7 \\
#' 6 & 16.7 \leq x_{in}
#' \end{cases}}
#'
#' The origin of these intervals is TODO: what exactly?
#'
#' @param layer A single-layered raster with non-negative values.
#' @returns The quantised raster.
#'
#' @keywords internal
#' @export
quantise_slope <- function(layer) {
    # Quantise the slope values
    slope_rcl <- data.matrix(data.frame(
        lower_bound = c(0, 1.72, 2.86, 5.71, 11.31, 16.7),
        upper_bound = c(1.72, 2.86, 5.71, 11.31, 16.7, Inf),
        mapped_to = c(1, 2, 3, 4, 5, 6)
    ))
    return(terra::classify(layer, rcl = slope_rcl))
}

#' Reproject Layer
#'
#' Reproject a single-layered raster onto a consistent grid using an
#' interpolation method suitable for integer-valued data. The resulting
#' raster has the following properties:
#'
#' - **Filetype:** Unsigned 8-t integer (INT1U)
#' - **CRS:** EPSG:27700
#' - **Resolution:** 20m
#' - **Domain:** A bounding box enclosing Scotland
#'
#' The raster is assumed to be integer-valued, and the interpolation method
#' passed to [terra::project] is `near`. The single exception is the special
#' case of `FIPS_N_Slope.tif`, where the raster is first quantised using
#' [biodt.recreation::quantise_slope] before being reprojected.
#'
#' @param infile Path to file containing the raster to be reprojected.
#' @param outfile Path that the reprojected raster will be written to.
#'
#' @keywords internal
#' @export
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

#' Reproject All
#'
#' Reproject all `.tif` files in a directory, writing the reprojected rasters
#' to another directory. The file names must be consistent with the features
#' as defined in the configuration file.
#' - **Precedes:** [biodt.recreation::reproject_all]
#'
#' @param indir Path to directory containing the input rasters.
#' @param outdir Path to directory in which to write the ouput rasters.
#'
#' @seealso [biodt.recreation::reproject_layer]
#'
#' @keywords internal
#' @export
reproject_all <- function(indir, outdir) {
    infiles <- list_files(indir, "tif", recursive = TRUE)
    feature_mappings <- get_feature_mappings(load_config())

    # NOTE: Stage 0 data contains more layers than are used in the final potential
    # Drop any tiffs whose name does not match a layer name in feature_mappings
    infiles <- infiles[intersect(names(infiles), names(feature_mappings))]
    stopifnot(all(names(feature_mappings) %in% names(infiles)))

    for (infile in infiles) {
        # TODO: fix this for nested indir/outdir
        outfile <- sub("^[^/]+", outdir, infile)
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

        message(paste("Reprojecting:", infile, "->", outfile))

        timed(reproject_layer)(infile, outfile)
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# One-hot representation                    #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

#' One Hot Layer
#'
#' Convert a single-layered integer-valued raster to a 'one-hot' representation
#' in which each unique value in the input raster is mapped to a unit vector in
#' a multi-dimensional output raster, where the number of dimensions in the output
#' equals the number of unique values in the input.
#'
#' @param infile Path to file containing the categorical raster.
#' @param outfile Path that the one-hot raster will be written to.
#' @param feature_mapping The mapping from feature names to raster values.
#'
#' @keywords internal
#' @export
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

#' One Hot All
#'
#' Apply [biodt.recreation::one_hot_layer] to all rasters in a directory.
#' The file names must be consistent with the features as defined in the
#' configuration file.
#' - **Preceded by:** [biodt.recreation::reproject_all]
#' - **Precedes:** [biodt.recreation::stack_all]
#'
#' @param indir Path to directory containing the input rasters.
#' @param outdir Path to directory in which to write the ouput rasters.
#'
#' @seealso [biodt.recreation::one_hot_layer]
#'
#' @keywords internal
#' @export
one_hot_all <- function(indir, outdir) {
    infiles <- list_files(indir, "tif", recursive = TRUE)
    feature_mappings <- get_feature_mappings(load_config())

    stopifnot(all(names(feature_mappings) %in% names(infiles)))

    for (infile in infiles) {
        # TODO: fix this for nested indir/outdir
        outfile <- sub("^[^/]+", outdir, infile)
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

        layer_name <- tools::file_path_sans_ext(basename(infile))
        feature_mapping <- feature_mappings[[layer_name]]

        message(paste("Converting to one-hot representation:", infile, "->", outfile))

        timed(one_hot_layer)(infile, outfile, feature_mapping)
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Create 4x stacked rasters                 #
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

#' Stack All
#'
#' Construct four multi-layered rasters for each of the four components
#' of the Recreational Potential model, by stacking the individual
#' one-hot rasters.
#' - **Preceded by:** [biodt.recreation::one_hot_all]
#' - **Precedes:** [biodt.recreation::compute_proximity_rasters]
#'
#' @param indir Path to directory containing the input rasters.
#' @param outdir Path to directory in which to write the ouput rasters.
#'
#' @keywords internal
#' @export
stack_all <- function(indir, outdir) {
    for (component in c("SLSRA", "FIPS_N", "FIPS_I", "Water")) {
        infiles <- list_files(file.path(indir, component), "tif", recursive = TRUE)

        outfile <- file.path(outdir, paste0(component, ".tif"))
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

        message(paste("Stacking", component, "into a single raster:", indir, "->", outfile))

        rasters <- lapply(infiles, terra::rast)
        stacked <- terra::rast(rasters)

        # NOTE: rast(list_of_rasters) does not preserve layer names!
        # Need to manually reapply them here (assumes order is preserved)
        layer_names <- unlist(lapply(rasters, names))
        names(stacked) <- layer_names

        terra::writeRaster(stacked, outfile, overwrite = TRUE)
    }
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
# Compute proximity (FIPS_I, Water only)    #
# --------------------------------------    #
# Description (to do)
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

#' Compute Distance
#'
#' Computes the distance to the nearest non-`NA` value in a raster using
#' haversine distance, writing straight to `outfile`. This is a thin wrapper
#' around [terra::distance].
#'
#' @param infile Path to file containing the input raster.
#' @param outfile Path that the output raster will be written to.
#'
#' @keywords internal
#' @export
compute_distance <- function(infile, outfile) {
    raster <- terra::rast(infile)

    terra::distance(
        raster,
        target = NA, # targets everything excluding the features (v expensive!)
        unit = "m",
        method = "haversine",
        filename = outfile,
        datatype = "FLT4S"
    )
}

# TODO: add link to paper, equation, values for kappa & alpha

#' Map distances to the unit interval
#'
#' Uses a logistic function to map positive distances \eqn{d}
#' to the unit interval \eqn{x \in [0, 1]}.
#'
#' \deqn{ x = \frac{\kappa + 1}{\kappa + \exp(\alpha d)} }
#'
#' @param x A raster
#' @param alpha Coefficient in the exponent
#' @param kappa A location parameter, of little importance frankly.
#'
#' @keywords internal
#' @export
map_distance_to_unit <- function(infile, outfile, kappa = 6, alpha = 0.01011) {
    logistic_func <- function(x) {
        (kappa + 1) / (kappa + exp(alpha * x))
    }
    raster <- terra::rast(infile)
    terra::app(
        raster,
        fun = logistic_func,
        filename = outfile
        # note that datatype inferred from raster - cannot be changed
    )
}

#' Compute Proximity Rasters
#'
#' For each layer in the `FIPS_I` and `Water` rasters, compute the distance
#' from each pixel to the nearest feature (non-`NA` value) using
#' [biodt.recreation::compute_distance], and map these distances to the unit
#' interval using [biodt.recreation::map_distance_to_unit].
#' - **Preceded by:** [biodt.recreation::stack_all]
#'
#' The intermediate rasters, which are the distances before mapping to the
#' unit interval, are retained in `outdir` with `_dist` in the file stem.
#'
#' **WARNING:** This function requires a significant amount of memory,
#' and is likely to crash your computer! It is intended to be run on
#' a high-memory system such as LUMI.
#'
#' @param indir Path to directory containing the input rasters.
#' @param outdir Path to directory in which to write the ouput rasters.
#'
#' @keywords internal
#' @export
compute_proximity_rasters <- function(indir, outdir) {
    for (component in c("FIPS_I", "Water")) {
        infile <- file.path(indir, paste0(component, ".tif"))
        dist_file <- file.path(outdir, paste0(component, "_dist.tif"))
        outfile <- file.path(outdir, paste0(component, ".tif"))
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

        message(paste("Performing distance calculation:", infile, "->", dist_file))
        timed(compute_distance)(infile, dist_file)

        message(paste("Mapping distance to unit interval:", dist_file, "->", outfile))
        timed(map_distance_to_unit)(dist_file, outfile)
    }

    for (component in c("SLSRA", "FIPS_N")) {
        infile <- file.path(indir, component)
        outfile <- file.path(outdir, paste0(component, ".tif"))
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)
        message(paste("Creating symbolic link:", infile, "->", outfile))
        file.symlink(infile, outfile)
    }
}
