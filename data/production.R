devtools::load_all("../")

terra::terraOptions(
    memfrac = 0.7,
    # datatype = "INTU1", # write everything as unsigned 8 bit int
    print = TRUE
)

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


time <- function(func, ...) {
    start_time <- Sys.time()
    result <- func(...)
    end_time <- Sys.time()
    delta <- difftime(end_time, start_time, units = "secs")
    cat("Took", delta, "seconds\n")
    return(result)
}


reproject_all <- function(indir, outdir) {
    infiles <- get_files(indir)

    # NOTE: Stage 0 data contains more layers than are used in the final potential
    # Drop any tiffs whose name does not match a layer name in .feature_mappings
    infiles <- infiles[intersect(names(infiles), names(.feature_mappings))]
    stopifnot(all(names(.feature_mappings) %in% names(infiles)))

    for (infile in infiles) {
        # TODO: fix this for nested indir/outdir
        outfile <- sub("^[^/]+", outdir, infile)
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

        message(paste("Reprojecting:", infile, "->", outfile))

        time(reproject_layer, infile, outfile)
    }
}

one_hot_all <- function(indir, outdir) {
    infiles <- get_files(indir)
    stopifnot(all(names(.feature_mappings) %in% names(infiles)))

    for (infile in infiles) {
        # TODO: fix this for nested indir/outdir
        outfile <- sub("^[^/]+", outdir, infile)
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

        layer_name <- tools::file_path_sans_ext(basename(infile))
        feature_mapping <- .feature_mappings[[layer_name]]

        message(paste("Converting to one-hot representation:", infile, "->", outfile))

        time(one_hot_layer, infile, outfile, feature_mapping)
    }
}


stack_all <- function(indir, outdir) {
    for (component in c("SLSRA", "FIPS_N", "FIPS_I", "Water")) {
        infiles <- get_files(file.path(indir, component))

        outfile <- file.path(outdir, paste0(component, ".tif"))
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

        message(paste("Stacking", component, "into a single raster:", indir, "->", outfile))

        rasters <- lapply(infiles, terra::rast)
        stacked <- terra::rast(rasters)

        # NOTE: rast(list_of_rasters) does not seem to preserve layer names!
        # Need to manually reapply them here (which assumes order is preserved)
        layer_names <- unlist(lapply(rasters, names))
        names(stacked) <- layer_names

        terra::writeRaster(stacked, outfile, overwrite = TRUE)
    }
}

compute_distance_fast <- function(indir, outdir) {
    for (component in c("FIPS_I", "Water")) {
        infile <- file.path(indir, paste0(component, ".tif"))
        dist_file <- file.path(outdir, paste0(component, "_dist.tif"))
        outfile <- file.path(outdir, paste0(component, ".tif"))
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

        message(paste("Performing distance calculation:", infile, "->", dist_file))
        time(compute_distance, infile, dist_file)

        message(paste("Mapping distance to unit interval:", dist_file, "->", outfile))
        time(map_distance_to_unit, dist_file, outfile)
    }

    for (component in c("SLSRA", "FIPS_N")) {
        infile <- file.path(indir, component)
        outfile <- file.path(outdir, paste0(component, ".tif"))
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)
        message(paste("Creating symbolic link:", infile, "->", outfile))
        file.symlink(infile, outfile)
    }
}

compute_distance_slow <- function(indir, outdir) {
    for (component in c("FIPS_I", "Water")) {
        infile <- file.path(indir, paste0(component, ".tif"))
        buf_file <- file.path(outdir, paste0(component, "_buf.tif"))
        dist_file <- file.path(outdir, paste0(component, "_dist.tif"))
        outfile <- file.path(outdir, paste0(component, ".tif"))
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

        message(paste("Computing buffer:", infile, "->", buf_file))
        time(compute_buffer, infile, buf_file)

        message(paste("Performing distance calculation:", buf_file, "->", dist_file))
        time(compute_distance_in_buffer, buf_file, dist_file)

        message(paste("Mapping distance to unit interval:", dist_file, "->", outfile))
        time(map_distance_to_unit, dist_file, outfile)
    }

    for (component in c("SLSRA", "FIPS_N")) {
        infile <- file.path(indir, component)
        outfile <- file.path(outdir, paste0(component, ".tif"))
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)
        message(paste("Creating symbolic link:", infile, "->", outfile))
        file.symlink(infile, outfile)
    }
}

# NOTE: nothing to do with distance. Misnomer. Fix
compute_distance_gauss <- function(indir, outdir) {
    for (component in c("FIPS_I", "Water")) {
        infile <- file.path(indir, paste0(component, ".tif"))
        outfile <- file.path(outdir, paste0(component, ".tif"))
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)

        message(paste("Applying Gaussian kernel:", infile, "->", outfile))
        time(gauss_blur, infile, outfile)
    }

    for (component in c("SLSRA", "FIPS_N")) {
        infile <- file.path(indir, component)
        outfile <- file.path(outdir, paste0(component, ".tif"))
        dir.create(dirname(outfile), recursive = TRUE, showWarnings = FALSE)
        message(paste("Creating symbolic link:", infile, "->", outfile))
        file.symlink(infile, outfile)
    }
}

# TODO: this doesn't seem to work - interactive() still seems to be TRUE
# if loading using source(production.R)...
if (!interactive()) {
    # reproject_all(indir = "Stage_0", outdir = "Stage_1")
    # one_hot_all(indir = "data/Stage_1", outdir = "data/Stage_2")
    # stack_all(indir = "data/Stage_2", outdir = "data/Stage_2")
    #compute_distance_fast(indir = "data/Stage_2", outdir = "data/Stage_3")
} else {
    print("dogs!")
}
