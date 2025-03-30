#!/bin/bash

Rscript -e "devtools::document(); devtools::load_all(); biodt.recreation::run_app(launch.browser = TRUE)"
