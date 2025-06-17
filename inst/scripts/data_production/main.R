# File:       main.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation2
# License:    MIT
# Copyright:  2025 BioDT
# Author(s):  Joe Marsh Rossney

# NOTE: Load package using library(...) if installed, and using
# devtools::load_all(...) if developing
git_root <- tryCatch(
    rprojroot::find_root(rprojroot::is_git_root),
    error = function(e) NULL
)
if (is.null(git_root)) {
    library(biodt.recreation)
} else {
    devtools::load_all(git_root)
}

terra::terraOptions(
    memfrac = 0.7,
    # datatype = "INTU1", # write everything as unsigned 8 bit int
    print = TRUE
)

# reproject_all(indir = "Stage_0", outdir = "Stage_1")
# one_hot_all(indir = "Stage_1", outdir = "Stage_2")
# stack_all(indir = "Stage_2", outdir = "Stage_3")
compute_proximity_rasters(
    indir = paste0(getwd(), "/inst/extdata/rasters/Stage_3"),
    outdir = paste0(getwd(), "/inst/extdata/rasters/Stage_4"),
    splitting = TRUE
)

# #check visually it makes sense
# water
# r <- terra::rast("inst/extdata/rasters/Stage_4/Water.tif")
# r_original <- terra::rast("inst/extdata/rasters/Stage_3/Water.tif")
# terra::plot(r)
# terra::plot(r_original, col = "red")
# Fips_I
r <- terra::rast("inst/extdata/rasters/Stage_4/FIPS_I.tif")
r_original <- terra::rast("inst/extdata/rasters/Stage_3/FIPS_I.tif")
terra::plot(r)
terra::plot(r_original, col = "red")
