# Data Production

## Usage

Copy the 'stage 0' data `Stage_0/` and `main.R` into the same directory, and run

```sh
Rscript main.R
```

But you need to already have the 'Stage 0' data, which is not currently available to the public.
Sorry!

We intend to extend this data production script backwards to the original raw data downloaded from the various repositories, at which point this repository will be updated.


## Singularity container

Build the container

```sh
sudo singularity build app.sif app.def
```

Run the containerised CLI with the same arguments as above, i.e. simply replace `Rscript main.R` with `singularity run app.sif`:

```sh
singularity run app.sif 
```
