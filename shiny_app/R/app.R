# Load biodt.recreation once here, before sourcing ui & server
biodt.recreation_pkg_path <- file.path(rprojroot::find_root(rprojroot::is_git_root), "model")
devtools::load_all(biodt.recreation_pkg_path)

source("ui.R")
source("server.R")

#' Run Shiny App
#'
#' Run the BioDT Recreational Potential Shiny App.
#'
#' @export
run_app <- function() {
    shiny::shinyApp(ui = ui(), server = server)
}

run_app()
