#!/bin/bash

mkdir -v tmp
cp inst/extdata/example_personas.csv tmp/

Rscript inst/cli/main.R --persona_file tmp/example_personas.csv --persona_name Hard_Recreationalist --xmin 300000 --xmax 310000 --ymin 700000 --ymax 710000 --pdf 
