#' Check Valid Persona
#'
#' @export
check_valid_persona <- function(persona) {
    if (all(sapply(persona, function(score) score == 0))) {
        message("All the persona scores are zero. At least one score must be non-zero.")
        message("Perhaps you have forgotten to load a persona?")
        return(FALSE)
    }
    return(TRUE)
}

#' List CSV Files
#'
#' Returns a list of the names of all CSV files in a directory.
#'
#' @param dir The directory in which to look.
#' @returns A list of names
#'
#' @export
list_csv_files <- function(dir) {
    return(list.files(path = dir, pattern = "\\.csv$", full.names = FALSE))
}

#' List Personas in File
#'
#' Returns a list of personas in a given file.
#'
#' @param persona_file The path to a persona file.
#' @returns A list of names.
#'
#' @export
list_personas_in_file <- function(persona_file) {
    personas <- names(read.csv(persona_file, nrows = 1))
    return(personas[personas != "index"])
}

list_users <- function(persona_dir) {
    lapply(list_csv_files(persona_dir), tools::file_path_sans_ext)
}

remove_non_alphanumeric <- function(string) {
    string <- gsub(" ", "_", string) # Spaces to underscore
    string <- gsub("[^a-zA-Z0-9_]+", "", string) # remove non alpha-numeric
    string <- gsub("^_+|_+$", "", string) # remove leading or trailing underscores
    return(string)
}

.data_extent <- terra::ext(terra::vect(system.file("extdata", "Scotland", "boundaries.shp", package = "biodt.recreation")))

#' Check Valid Bbox
#'
#' Check that a bounding box defines a valid area in which to compute the
#' Recreational Potential. It must be in Scotland and have an acceptable area.
#'
#' @param bbox A `SpatExtent` object defining the bounding box.
#' @param min_area The minimum allowed area.
#' @param max_area The maximum allowed area.
#' @returns `TRUE` if the bbox is valid, `FALSE` otherwise.
#'
#' @export
check_valid_bbox <- function(bbox, min_area = 1e4, max_area = 1e9) {
    if (is.null(bbox)) {
        message("No area has been selected. Please select an area.")
        return(FALSE)
    }
    area <- (terra::xmax(bbox) - terra::xmin(bbox)) * (terra::ymax(bbox) - terra::ymin(bbox))
    if (area > max_area) {
        message(paste(
            "The area you have selected is too large to be computed at this time",
            "(", sprintf("%.1e", area), ">", max_area, " m^2 ).",
            "Please draw a smaller area."
        ))
        return(FALSE)
    }
    if (area < min_area) {
        message(paste(
            "The area you have selected is too small",
            "(", round(area), "<", min_area, " m^2 ).",
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
