library(biodt.recreation)

# Path to a CSV file containing one or more personas
csv_path <- get_preset_persona_file()

# Load a single persona from this file
loaded_persona <- load_persona(csv_path, "Hard_Recreationalist")
