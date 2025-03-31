#!/bin/bash

# Run this from the repository root!

Rscript -e "
devtools::document();
devtools::load_all();
biodt.recreation::run_app(data_dir = '../full_data', launch.browser = TRUE)
"
