#' @export
run_app <- function() {
    app <- system.file("shiny_app", "app.R", package = "biodt.recreation")
    shiny::runApp(app)
}
