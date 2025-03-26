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

check_valid_bbox <- function(bbox, min_area = 1e4, max_area = 1e9) {
    if (is.null(bbox)) {
        message("No area has been selected. Please select an area.")
        return(FALSE)
    }
    tryCatch(
        {
            biodt.recreation::assert_bbox_intersects_scotland(bbox)
        },
        error = function(e) {
            message(conditionMessage(e))
            return(FALSE)
        },
        warning = function(w) {
            message(conditionMessage(w))
        }
    )
    tryCatch(
        {
            biodt.recreation::assert_bbox_is_valid_size(bbox, min_area, max_area)
        },
        error = function(e) {
            message(conditionMessage(e))
            return(FALSE)
        },
        warning = function(w) {
            message(conditionMessage(w))
        }
    )
    return(TRUE)
}
