source("ui.R")
source("server.R")

biodt.recreation_pkg_path <- file.path(rprojroot::find_root(rprojroot::is_git_root), "model")
devtools::load_all(biodt.recreation_pkg_path)

shinyApp(ui = ui, server = server)
