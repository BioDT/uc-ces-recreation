# Rscript main.R --persona_file example/personas.csv --xmin=300000 --xmax=310000 --ymin 700000 --ymax 710000 --persona_name Hard_Recreationalist --pdf

devtools::load_all("../model")

# Display full command
cmd <- paste(base::commandArgs(), collapse = " ")
cat(cmd, "\n")

# Get cmd args
args <- R.utils::commandArgs(
    trailingOnly = TRUE,
    asValues = TRUE,
    defaults = list(persona_name = NULL, pdf = FALSE), # serves no purpose tbh
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

persona <- biodt.recreation::load_persona(args$persona_file, name = args$persona_name)

bbox <- terra::ext(args$xmin, args$xmax, args$ymin, args$ymax)

# Check that the bbox is valid
scotland <- terra::ext(-10000, 660000, 460000, 1220000)
if (!terra::relate(bbox, scotland, relation = "within")) {
    stop("Bounding box coordinates are not contained with the Scotland bbox")
}

# Run the model
layers <- biodt.recreation::compute_potential(persona, bbox = bbox)

# Write the output raster
output_dir <- dirname(args$persona_file)
output_name <- paste(
    c(
        tools::file_path_sans_ext(basename(args$persona_file)),
        args$persona_name,
        format(round(args$xmin), scientific = FALSE),
        format(round(args$xmax), scientific = FALSE),
        format(round(args$ymin), scientific = FALSE),
        format(round(args$ymax), scientific = FALSE)
    ),
    collapse = "_"
)
output_path <- file.path(output_dir, paste0(output_name, ".tif"))

message(paste("Writing raster to path:", output_path))
if (file.exists(output_path)) {
    warning("The existing file will be overwritten!")
}

terra::writeRaster(layers, output_path, overwrite = TRUE)

if (args$pdf) {
    output_path <- file.path(output_dir, paste0(output_name, ".pdf"))
    message(paste("Writing pdf to path:", output_path))

    pdf(file = output_path)
    terra::plot(layers)
    dev.off()
}
