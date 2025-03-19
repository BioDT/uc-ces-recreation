.assert_valid_persona <- function(persona) {
    expected_names <- load_config()[["Name"]]
    if (!identical(sort(names(persona)), sort(expected_names))) {
        stop("Error: malformed names in the persona vector")
    }
    if (!all(persona == floor(persona))) {
        stop("Error: persona contains non-integer values")
    }
}

#' @export
read_persona_csv <- function(csv_path) {
    # Read csv as a dataframe of integers, throwing an error for non-integer elements
    df <- readr::read_csv(
        csv_path,
        col_types = readr::cols(
            index = readr::col_character(),
            .default = readr::col_integer()
        )
    )
    # NOTE: this may be redundant given index specified in col_types
    if (!"index" %in% colnames(df)) {
        stop("Error: the file does not contain an index column")
    }

    if (!ncol(df) > 1) {
        stop("Error: the file does not contain any personas")
    }

    return(df)
}

#' Load Persona
#'
#' Loads a single persona from a csv file containing one or more personas.
#' If the file contains more than one persona (i.e. columns), a name specifying
#' which personal (column) to load must also be provided.
#'
#' @param csv_path `character` Path to a csv file containing one or more personas
#' @param name `character` Name of the persona, which should match a column name
#'
#' @return `integer` A named vector of integers representing the persona
#'
#' @export
load_persona <- function(csv_path, name = NULL) {
    message(paste0("Loading persona '", name, "' from file '", csv_path, "'"))

    df <- read_persona_csv(csv_path)

    stopifnot(names(df)[1] == "index")

    if (is.null(name)) {
        if (ncol(df) > 2) {
            stop("Error: A name is required when the persona file contains >1 persona")
        }
        # There is only one persona in the file (after index)
        scores <- df[[2]]
    } else {
        # Select the column with the provided name
        scores <- df[[name]]
    }

    # Convert to named vector
    persona <- setNames(scores, df[["index"]])

    .assert_valid_persona(persona)

    return(persona)
}

#' Save Persona
#'
#' Saves a persona to a csv file. If the csv file already exists, the persona
#' will be appended as a new column, unless the provided name matches an existing
#' column, in which case it will overwrite the existing data.
#'
#' @param persona `integer` A named vector of integers representing the persona
#' @param csv_path `character` Path to write a csv file, which may already exist
#' @param name `character` Name of the persona
#'
#' @export
save_persona <- function(persona, csv_path, name, overwrite = FALSE) {
    if (name == "index") {
        message("Cannot name the persona 'index'. Persona not saved")
        return()
    }
    # TODO: add messages here, without polluting printed user info in shiny app
    .assert_valid_persona(persona)

    # If file exists, we need to append the new persona carefully, making
    # sure the row names of the new persona are aligned with the 'index'
    # column of the dataframe
    if (file.exists(csv_path)) {
        df <- read_persona_csv(csv_path)

        # Check if we are overwriting an existing persona and delete the column if so
        # since otherwise we end up with `name1` and `name2` or something like that
        if (name %in% colnames(df)) {
            message(paste0("A persona with name '", name, "' already exists"))
            if (overwrite) {
                message("This will be overwritten with the new persona")
                df[[name]] <- NULL
            } else {
                message("Cannot overwrite existing persona. Please choose a different name")
                return()
            }
        }

        # Reorder persona to align it with the `index` column, then add
        # the reordered list to the data.frame as a new column
        df[[name]] <- persona[df[["index"]]]
    } else {
        # If file does *not* exist, simply crete a dataframe with two columns,
        # 'index' and '<name>'
        df <- data.frame(index = names(persona))
        df[[name]] <- persona
    }

    readr::write_csv(df, csv_path)
}
