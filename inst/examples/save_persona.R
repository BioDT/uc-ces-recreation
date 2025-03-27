library(biodt.recreation)

csv_path <- system.file("extdata", "example_personas.csv", package = "biodt.recreation")
loaded_persona <- load_persona(csv_path, name = "Hard_Recreationalist")

temp_file <- tempfile(fileext = ".csv")
save_persona(loaded_persona, temp_file, "Hard_Recreationalist_Copy")
