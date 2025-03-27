#' @export
run_app <- function(...) {
    app_file <- system.file("shiny_app", "app.R", package = "biodt.recreation", mustWork = TRUE)
    shiny::runApp(app_file, ...)
}
