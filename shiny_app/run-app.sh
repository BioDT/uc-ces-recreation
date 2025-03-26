#!/bin/bash

Rscript -e "shiny::runApp('R/app.R', launch.browser = TRUE)"
#Rscript -e "biodt.recreation.app::run_app()"
