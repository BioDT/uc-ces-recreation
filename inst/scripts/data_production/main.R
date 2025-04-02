# Replace with library(biodt.recreation) if installed
root <- rprojroot::find_root(rprojroot::is_git_root)
devtools::load_all(root)


terra::terraOptions(
    memfrac = 0.7,
    # datatype = "INTU1", # write everything as unsigned 8 bit int
    print = TRUE
)

.feature_mappings <- get_feature_mappings(load_config())


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

# reproject_all(indir = "Stage_0", outdir = "Stage_1")
# one_hot_all(indir = "data/Stage_1", outdir = "data/Stage_2")
# stack_all(indir = "data/Stage_2", outdir = "data/Stage_2")
# compute_distance_fast(indir = "data/Stage_2", outdir = "data/Stage_3")
