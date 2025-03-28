#' @export
run_app <- function(...) {
    app <- shiny::shinyApp(ui = ui(), server = server())
    shiny::runApp(app, ...)
}
