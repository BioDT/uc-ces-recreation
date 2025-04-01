library(biodt.recreation)

# Example persona: 'Hard_Recreationalist'
example_persona <- get_example_persona()

# create a temporary file to save
new_persona_file <- tempfile(fileext = ".csv")

# Save a copy of the Hard_Recreationalist persona
save_persona(example_persona, new_persona_file, "Hard_Copy")

# Check the file contents
read_persona_csv(new_persona_file)

# Create a random new person
feature_names <- load_config()[["Name"]]
random_persona <- stats::setNames(
    sample(0:10, size = 87, replace = TRUE),
    feature_names
)

# Append it to the file
save_persona(random_persona, new_persona_file, "Random")

# Check the file contents
read_persona_csv(new_persona_file)

unlink(new_persona_file)
