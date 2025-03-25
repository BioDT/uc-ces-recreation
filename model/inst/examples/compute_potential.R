library(biodt.recreation)

persona <- load_persona(
    csv_path = system.file("extdata", "example_personas.csv", package = "biodt.recreation"),
    name = "Hard_Recreationalist"
)
data_dir <- get_default_data_dir()
bbox <- system.file("extdata", "Bush", "Bush.shp", package = "biodt.recreation")

rec_pot <- compute_potential(persona, data_dir, bbox = bbox)
