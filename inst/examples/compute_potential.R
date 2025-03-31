library(biodt.recreation)

persona <- load_persona(get_example_persona_file(), "Hard_Recreationalist")
bbox <- terra::ext(terra::vect(get_example_bbox()))
data_dir <- get_default_data_dir()

# Compute all layers
layers <- compute_potential(persona, bbox)

# Get the full RP layer only
rp <- layers[["Recreational_Potential"]]
