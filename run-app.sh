#!/bin/bash

Rscript -e "shiny::runApp('inst/shiny_app/app.R', launch.browser = TRUE)"
