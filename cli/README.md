# Recreational Potential Model - CLI

## Basic usage

```sh
Rscript main.R --persona_file PERSONA_FILE --xmin XMIN --xmax XMAX --ymin YMIN --ymax YMAX --persona_name PERSONA_NAME --pdf
```

e.g.

```sh
Rscript main.R --persona_file examples/personas.csv --xmin=300000 --xmax=310000 --ymin=700000 --ymax=710000 --persona_name Hard_Recreationalist --pdf
```

Currently this generates 2 things

1. a `.tif` file with 5 layers corresponding to the 4 components of the Recreational Potential, plus the Recreational Potential itself
2. a `.pdf` file with plots of these 5 layers, for sanity checking

Both outputs are automatically named according to the persona and bbox provided, and are saved to the same directory as the persona file.


## Singularity container

To do

