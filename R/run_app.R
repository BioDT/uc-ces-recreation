# NOTE: this will not work unless shiny_app/ is moved back to isnt/
.run_app <- function() {
    app <- system.file("shiny_app", "app.R", package = "biodt.recreation")
    shiny::runApp(app)
}
