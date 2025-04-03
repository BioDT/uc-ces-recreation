# Replace with library(biodt.recreation) if installed
root <- rprojroot::find_root(rprojroot::is_git_root)
devtools::load_all(root)

terra::terraOptions(
    memfrac = 0.7,
    # datatype = "INTU1", # write everything as unsigned 8 bit int
    print = TRUE
)

reproject_all(indir = "Stage_0", outdir = "Stage_1")
one_hot_all(indir = "Stage_1", outdir = "Stage_2")
stack_all(indir = "Stage_2", outdir = "Stage_3")
compute_proximity_rasters(indir = "Stage_3", outdir = "Stage_4")
