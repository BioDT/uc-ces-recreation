here::i_am("run.R")
devtools::load_all("../model")

# Display full command
cmd <- paste(base::commandArgs(), collapse = " ")
cat(cmd, "\n")

# Get cmd args
args <- R.utils::commandArgs(
    trailingOnly = TRUE,
    asValues = TRUE,
    defaults = list(persona_name = NULL, output = "."),
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
if (length(args) > 7) {
    stop("Too many arguments provided.")
}

persona <- load_persona(args$persona_file, name = args$persona_name)

# Check that the bbox is valid
bbox <- terra::ext(args$xmin, args$xmax, args$ymin, args$ymax)
scotland <- terra::ext(-10000, 660000, 460000, 1220000)

if (!terra::relate(bbox, scotland, relation = "within")) {
    stop("Bounding box coordinates are not contained with the Scotland bbox")
}

# TODO: elsewhere, function to check bbox is valid and is not too big or too small

# TODO: check that the output is valid (does not exist already?)


raster_dir <- "data/"

# Run the model
layers <- compute_potential(persona, raster_dir, bbox = bbox)

terra::writeRaster(layers, "testing.tif", overwrite = TRUE)
