library(biodt.recreation)

persona <- load_persona(get_example_persona_file(), "Hard_Recreationalist")
bbox <- terra::ext(terra::vect(get_example_bbox()))
data_dir <- get_default_data_dir()

# Compute SLSRA component
slsra <- compute_component("SLSRA", persona, bbox)

# Compute Water component, specifying data dir
water <- compute_component("Water", persona, bbox, data_dir = data_dir)
