library(biodt.recreation)

persona <- load_persona(
    csv_path = system.file("extdata", "example_personas.csv", package = "biodt.recreation"),
    name = "Hard_Recreationalist"
)
data_dir <- system.file("extdata", package = "biodt.recreation")
bbox <- terra::vect(
    system.file("extdata", "Bush", "Bush.shp", package = "biodt.recreation")
)

compute_potential(persona, data_dir, bbox = bbox)
