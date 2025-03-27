
#' Assert to Bool
#'
#' @export
assert_to_bool <- function(assert_func) {
    msg_func <- function(...) {
        tryCatch(
            assert_func(...),
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
    return(msg_func)
}
