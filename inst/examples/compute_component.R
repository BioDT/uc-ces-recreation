library(biodt.recreation)

persona <- get_example_persona()
bbox <- get_example_bbox()
data_dir <- get_example_data_dir()

# Compute SLSRA component
slsra <- compute_component("SLSRA", persona, bbox, data_dir)

# Compute Water component
water <- compute_component("Water", persona, bbox, data_dir)
