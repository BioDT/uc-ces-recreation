library(biodt.recreation)

# Take any path to a file that can be loaded using terra::rast
raster_path <- file.path(get_example_data_dir(), "Water.tif")

# Load the full raster
raster <- load_raster(raster_path)

# `crop` is a `SpatExtent`
# TODO

# `crop` is a `SpatVector`
# TODO

# `crop` is a path
# TODO
