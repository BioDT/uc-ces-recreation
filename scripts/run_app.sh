#!/bin/bash

# Run this from the repository root!

Rscript -e "
devtools::document();
devtools::load_all();
biodt.recreation::download_data();
biodt.recreation::run_app(launch.browser = TRUE)
"
