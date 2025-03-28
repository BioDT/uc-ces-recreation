# File:       app_run.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation2
# License:    MIT
# Copyright:  2025 BioDT
# Author(s):  Joe Marsh Rossney

#' Run the Recreational Potential App
#'
#' @param persona_dir Path to a directory containing persona files.
#' @param data_dir Path to the directory containing the raster data.
#' @param ... Additional arguments passed to [shiny::runApp].
#'
#' @export
run_app <- function(persona_dir = NULL, data_dir = NULL, ...) {
    app <- shiny::shinyApp(ui = ui(), server = server(persona_dir, data_dir))
    shiny::runApp(app, ...)
}
