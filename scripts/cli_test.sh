#!/bin/bash

mkdir -v tmp
cp inst/extdata/preset_personas.csv tmp/

Rscript inst/cli/main.R --persona_file tmp/preset_personas.csv --persona_name Hard_Recreationalist --xmin 300000 --xmax 310000 --ymin 700000 --ymax 710000 --pdf 
