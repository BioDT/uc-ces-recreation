.max_area <- 1e9 # about 1/4 of the Cairngorms area
.min_area <- 1e4
.data_extent <- terra::ext(terra::vect(system.file("extdata", "Scotland", "boundaries.shp", package = "biodt.recreation")))

check_valid_bbox <- function(bbox) {
    if (is.null(bbox)) {
        message("No area has been selected. Please select an area.")
        return(FALSE)
    }
    area <- (terra::xmax(bbox) - terra::xmin(bbox)) * (terra::ymax(bbox) - terra::ymin(bbox))
    if (area > .max_area) {
        message(paste(
            "The area you have selected is too large to be computed at this time",
            "(", sprintf("%.1e", area), ">", .max_area, " m^2 ).",
            "Please draw a smaller area."
        ))
        return(FALSE)
    }
    if (area < .min_area) {
        message(paste(
            "The area you have selected is too small",
            "(", round(area), "<", .min_area, " m^2 ).",
            "Please draw a larger area."
        ))
        return(FALSE)
    }

    entirely_within <- (
        terra::xmin(bbox) > terra::xmin(.data_extent) &&
            terra::xmax(bbox) < terra::xmax(.data_extent) &&
            terra::ymin(bbox) > terra::ymin(.data_extent) &&
            terra::ymax(bbox) < terra::ymax(.data_extent)
    )
    if (entirely_within) {
        message(paste("Selected an area of", sprintf("%.1e", area), "m^2"))
        return(TRUE)
    }

    entirely_outside <- (
        terra::xmin(bbox) > terra::xmax(.data_extent) ||
            terra::xmax(bbox) < terra::xmin(.data_extent) ||
            terra::ymin(bbox) > terra::ymax(.data_extent) ||
            terra::ymax(bbox) < terra::ymin(.data_extent)
    )

    if (entirely_outside) {
        message("Error: The area you have selected is entirely outside the region where we have data.")
        return(FALSE)
    }

    message("Warning: Part of the area you have selected exceeds the boundaries where we have data.")
    return(TRUE)
}

check_valid_persona <- function(persona) {
    if (all(sapply(persona, function(score) score == 0))) {
        message("All the persona scores are zero. At least one score must be non-zero.")
        message("Perhaps you have forgotten to load a persona?")
        return(FALSE)
    }
    return(TRUE)
}

list_persona_files <- function(persona_dir) {
    return(list.files(path = persona_dir, pattern = "\\.csv$", full.names = FALSE))
}

list_users <- function(persona_dir) lapply(list_persona_files(persona_dir), tools::file_path_sans_ext)

list_personas_in_file <- function(file_name) {
    personas <- names(read.csv(file.path(.persona_dir, file_name), nrows = 1))
    return(personas[personas != "index"])
}

remove_non_alphanumeric <- function(string) {
    string <- gsub(" ", "_", string) # Spaces to underscore
    string <- gsub("[^a-zA-Z0-9_]+", "", string) # remove non alpha-numeric
    string <- gsub("^_+|_+$", "", string) # remove leading or trailing underscores
    return(string)
}
