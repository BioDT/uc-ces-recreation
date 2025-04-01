library(biodt.recreation)

# Any path to a persona file
csv_path <- get_preset_persona_file()

# Read the file into a data.frame
loaded_personas <- read_persona_csv(csv_path)
