# File:       data_download.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation2
# License:    MIT
# Copyright:  2025 BioDT
# Author(s):  Joe Marsh Rossney

options(timeout = 180)

# TODO: currently using dropbox, but switch to Zenodo once the data is published.

# https://www.dropbox.com/scl/fo/zvm0bgajsa0iuamzthn8u/ALxdRaPDZqkKKsyWijMW2cQ?rlkey=8tgvzv4a2ynawqszz62fku3p0&st=24i8e965&dl=0  # nolint
.data_urls <- list(
  SLSRA = "https://www.dropbox.com/scl/fi/r82a7s5jr97ys2lwmmfxv/SLSRA.tif?rlkey=6r2ei8z7lfv8rul8fcnblq1qw&st=mptknrao&dl=1", # nolint
  FIPS_N = "https://www.dropbox.com/scl/fi/mui9hqtqgoyi33usrz8za/FIPS_N.tif?rlkey=z2v2obdwd1s77f4n6mhn3mcuu&st=a2i2gnhq&dl=1", # nolint
  FIPS_I = "https://www.dropbox.com/scl/fi/nlvrblpj13251y9du62pt/FIPS_I.tif?rlkey=vfnobz6vvh88qxb06k1kcr80x&st=4j25s453&dl=1", # nolint
  Water = "https://www.dropbox.com/scl/fi/31wq85g9k1zfmnofw68kw/Water.tif?rlkey=m2xtuawo1nrqgshexi8ic66qr&st=4hrmzzjd&dl=1" # nolint
)

# https://www.dropbox.com/scl/fo/z2ljmtczstxo4kfz0599c/ABr9fK22ktYMVqAW5OEhiE8?rlkey=rpp29dq7qij26kr8cboz08mnu&st=8tuukw2t&dl=0  # nolint
.example_data_urls <- list(
  SLSRA = "https://www.dropbox.com/scl/fi/i6ext6ujffrzk7ljaq1z8/SLSRA.tif?rlkey=f6scjky756f8x76834j24d7lr&st=6gwh32bf&dl=1", # nolint
  FIPS_N = "https://www.dropbox.com/scl/fi/b9iz79f6mti76nqgp904k/FIPS_N.tif?rlkey=yyhp2akxn4u56i9xh8aqg9qjl&st=lwvqr0lq&dl=1", # nolint
  FIPS_I = "https://www.dropbox.com/scl/fi/b91n82eci1o3k5x4wtf1e/FIPS_I.tif?rlkey=ohy9ynb61hdrab2oi176lcaia&st=j4a5hluz&dl=1", # nolint
  Water = "https://www.dropbox.com/scl/fi/u9k1gnln8eac8zkn3ow4q/Water.tif?rlkey=obo59hgyzg9inevze4w3kptm7&st=29yg7olq&dl=1" # nolint
)

.download_data <- function(dest, example) {
  if (!dir.exists(dest)) dir.create(dest)

  if (example) urls <- .example_data_urls else urls <- .data_urls

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
  .download_data(dest, example = FALSE)
}


# NOTE: this may be redundant now the example data is bundled into the package

#' Download Example Data
#'
#' Downloads some smaller example dara for testing the model.
#'
#' @param dest Optional non-default path to a directory in which to save the data.
#'
#' @keywords internal
#' @export
download_example_data <- function(dest = NULL) {
  if (is.null(dest)) {
    dest <- get_example_data_dir()
  }
  .download_data(dest, example = TRUE)
}
