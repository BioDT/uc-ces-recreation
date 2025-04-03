# Recreational Potential Model - CLI

If you cloned the repository from GitHub, you will find this script in `uc-ces-recreation/inst/cli/main.R`.

If you installed the package, you will need to access the script `path/to/biodt.recreation/cli/main.R`.
To extract this path from within R, try

```R
script_path <- system.file("scripts", "cli", "main.R", package = "biodt.recreation")
```


## Basic usage

```sh
Rscript main.R --persona_file PERSONA_FILE --persona_name PERSONA_NAME --xmin XMIN --xmax XMAX --ymin YMIN --ymax YMAX --pdf
```

e.g.

```sh
Rscript main.R --persona_file examples/personas.csv --persona_name Hard_Recreationalist --xmin=300000 --xmax=310000 --ymin=700000 --ymax=710000 --pdf
```

Currently this generates 2 things

1. a `.tif` file with 5 layers corresponding to the 4 components of the Recreational Potential, plus the Recreational Potential itself
2. a `.pdf` file with plots of these 5 layers, for sanity checking

Both outputs are automatically named according to the persona and bbox provided, and are saved to the same directory as the persona file.


## Singularity container

Build the container

```sh
sudo singularity build app.sif app.def
```

Run the containerised CLI with the same arguments as above, i.e. simply replace `Rscript main.R` with `singularity run app.sif`:

```sh
singularity run app.sif --persona_file PERSONA_FILE --xmin XMIN --xmax XMAX --ymin YMIN --ymax YMAX --persona_name PERSONA_NAME --pdf
```
