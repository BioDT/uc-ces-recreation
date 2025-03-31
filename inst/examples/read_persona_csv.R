library(biodt.recreation)

# Any path to a persona file
csv_path <- biodt.recreation::get_example_persona_file()

# Read the file into a data.frame
loaded_personas <- read_persona_csv(csv_path)
