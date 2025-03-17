# Rscript run.R --persona_file examples.csv --xmin=300000 --xmax=310000 --ymin 700000 --ymax 710000 --persona_name Hard_Recreationalist

here::i_am("run.R")
devtools::load_all("../model")

raster_dir <- "data/"

# Display full command
cmd <- paste(base::commandArgs(), collapse = " ")
cat(cmd, "\n")

# Get cmd args
args <- R.utils::commandArgs(
    trailingOnly = TRUE,
    asValues = TRUE,
    defaults = list(persona_name = NULL), # serves no purpose tbh
    adhoc = TRUE, # attempts to convert arg types
    unique = TRUE,
    excludeReserved = TRUE,
    excludeEnvVars = TRUE
)


# Check that the correct args were provided
if (is.null(args[["persona_file"]])) {
    stop("Missing argument: please provide `--persona_file=<path>`")
}
for (coord in c("xmin", "xmax", "ymin", "ymax")) {
    if (is.null(args[[coord]])) {
        stop(paste0("Missing argument: please provide `--", coord, "=<value>`"))
    }
}

# TODO: additional argument checks would be wise

persona <- load_persona(args$persona_file, name = args$persona_name)

bbox <- terra::ext(args$xmin, args$xmax, args$ymin, args$ymax)

# Check that the bbox is valid
scotland <- terra::ext(-10000, 660000, 460000, 1220000)
if (!terra::relate(bbox, scotland, relation = "within")) {
    stop("Bounding box coordinates are not contained with the Scotland bbox")
}

# Run the model
layers <- compute_potential(persona, raster_dir, bbox = bbox)

# Write the output raster
output_name <- paste(c("raster", args$persona_name, args$xmin, args$xmax, args$ymin, args$ymax), collapse = "_")
output_path <- file.path(dirname(args$persona_file), paste0(output_name, ".tif"))
terra::writeRaster(layers, output_path, overwrite = TRUE)
