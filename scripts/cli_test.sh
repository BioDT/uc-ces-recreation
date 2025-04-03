#!/bin/bash

mkdir -v tmp
cp inst/extdata/personas/presets.csv tmp/

Rscript inst/scripts/cli/main.R --persona_file tmp/presets.csv --persona_name Hard_Recreationalist --xmin 300000 --xmax 310000 --ymin 700000 --ymax 710000 --pdf 
