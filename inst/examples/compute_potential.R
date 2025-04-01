library(biodt.recreation)

persona <- get_example_persona()
bbox <- get_example_bbox()
data_dir <- get_example_data_dir()

# Compute all layers
layers <- compute_potential(persona, bbox, data_dir)

# Get the full RP layer only
rp <- layers[["Recreational_Potential"]]
