# File:       data_download.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation
# License:    MIT
# Copyright:  2025 BioDT and the UK Centre for Ecology & Hydrology
# Author(s):  Joe Marsh Rossney

# TODO: currently using dropbox, but switch to Zenodo once the data is published.

# https://www.dropbox.com/scl/fo/zvm0bgajsa0iuamzthn8u/ALxdRaPDZqkKKsyWijMW2cQ?rlkey=8tgvzv4a2ynawqszz62fku3p0&st=24i8e965&dl=0  # nolint
.data_urls <- list(
    SLSRA = "https://www.dropbox.com/scl/fi/r82a7s5jr97ys2lwmmfxv/SLSRA.tif?rlkey=6r2ei8z7lfv8rul8fcnblq1qw&st=mptknrao&dl=1", # nolint
    FIPS_N = "https://www.dropbox.com/scl/fi/mui9hqtqgoyi33usrz8za/FIPS_N.tif?rlkey=z2v2obdwd1s77f4n6mhn3mcuu&st=a2i2gnhq&dl=1", # nolint
    FIPS_I = "https://www.dropbox.com/scl/fi/s6a8okl650jezbtkgx83k/FIPS_I.tif?rlkey=roi91ysounwj0b7tcxeyqait9&st=7oh4pi7s&dl=1", # nolint
    Water = "https://www.dropbox.com/scl/fi/c8o1ldlv5fr33e9pu03hc/Water.tif?rlkey=l3h0ibcyxjvza100kv2cqkzmy&st=z2v8m1lr&dl=1" # nolint
)

#' Get Data Dir
#'
#' Construct the path to the directory containing the raster data by default,
#' i.e. assuming no argument was provided to [biodt.recreation::download_data].
#' In the event that the data directory is not found, a warning message will be
#' printed, but the path will still be returned.
#'
#' @returns Path to the data directory.
#'
#' @export
get_data_dir <- function() {
    # extdata/rasters contains both Scotland (data_dir) and Bush
    raster_dir <- system.file("extdata", "rasters",
        package = "biodt.recreation", mustWork = TRUE
    )
    data_dir <- file.path(raster_dir, "Scotland")

    # Warn if it does not exist, but don't error out since perhaps only
    # the path is required, e.g. for download_data() itself
    if (!dir.exists(data_dir)) {
        warning("Data directory does not exist. Have you run `download_data()`?")
    }

    return(data_dir)
}

#' Download Data
#'
#' Downloads the data required to compute Recreational Potential.
#'
#' @param dest Optional non-default path to a directory in which to save the data.
#'
#' @export
download_data <- function(dest = NULL) {
    if (is.null(dest)) {
        dest <- get_data_dir()
    }
    if (!dir.exists(dest)) dir.create(dest)

    urls <- .data_urls

    for (layer in names(urls)) {
        destfile <- file.path(dest, paste0(layer, ".tif"))

        if (file.exists(destfile)) {
            message(paste("Skipping download of", layer, "since", destfile, "already exists."))
        } else {
            message(paste("Downloading", layer, "raster to", destfile))

            utils::download.file(urls[[layer]], destfile = destfile, method = "auto")
        }
    }
}
