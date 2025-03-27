#!/bin/bash

#Rscript -e "shiny::runApp('inst/shiny_app/app.R', launch.browser = TRUE)"
Rscript -e "devtools::document(); devtools::load_all(); biodt.recreation::run_app(launch.browser = TRUE)"
