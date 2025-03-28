# File:       utils.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation2
# License:    MIT
# Copyright:  2025 BioDT
# Author(s):  Joe Marsh Rossney

#' Errors as Messages
#'
#' Given a function that may throw an error, e.g. via `stop()`, produce
#' a function that instead prints the error message without crashing.
#' This is achieved by wrapping the function execution in a `tryCatch` 
#' and capturing any errors or warnings as a message.
#'
#' Note that in the case of an error being thrown, the function will 
#' return the error. This can be checked by testing the return type, i.e.
#' `inherits(return_value$result, "simpleError")`, which will evaluate to
#' `TRUE` if an error was returned.
#'
#' @param func A function which can error out.
#' @returns The wrapped function.
#'
#' @keywords internal
#' @export
errors_as_messages <- function(func) {
    wrapped_func <- function(...) {
        result <- tryCatch(
            func(...),
            error = function(e) {
                message(conditionMessage(e))
                return(e)
            },
            warning = function(w) {
                message(conditionMessage(w))
            }
        )
        return(result)
    }
    return(wrapped_func)
}

#' Assert to Bool
#'
assert_to_bool <- function(func) {
    wrapped_func <- function(...) {
        tryCatch(
            func(...),
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
    return(wrapped_func)
}

#' Capture Messages
#'
#' Modify a function so that, when executed, any messages that would
#' usually be printed to stdout are instead captured and held in a
#' variable. The wrapped function returns a pair `(result, message)`
#' that contains the original result and the captured messages.
#'
#' @param func A function that includes messages.
#' @returns The wrapped function.
#'
#' @keywords internal
#' @export
capture_messages <- function(func) {
    wrapped_func <- function(...) {
        message <- utils::capture.output(
            result <- func(...),
            type = "message"
        )
        message <- paste(message, collapse = "\n")  # split messages over lines
        return(list(result = result, message = message))
    }
    return(wrapped_func)
}

#' Make Safe String
#'
#' Conver an arbitrary string into a 'safe' one that can be used in
#' file names and data.frame column names. This involves replacing
#' spaces with underscores and removing any characters that are not
#' alpha-numeric.
#'
#' @param string The input string.
#' @returns The 'safe' string.
#'
#' @keywords internal
#' @export
make_safe_string <- function(string) {
    string <- gsub(" ", "_", string) # Spaces to underscore
    string <- gsub("[^a-zA-Z0-9_]+", "", string) # remove non alpha-numeric
    string <- gsub("^_+|_+$", "", string) # remove leading or trailing underscores
    return(string)
}
