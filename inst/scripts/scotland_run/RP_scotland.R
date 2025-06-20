
#############
### STEP 1 ##
#############

# download the other 2 scotland wide files in the directory
library(biodt.recreation)
options(timeout = 1000) 
#download_data(dest = here::here("inst", "extdata", "rasters", "Scotland"))

###### manually substitute the 2 new distance files from vm into the rasters/scotland/folder

### run RP model

#### PERSONAS

personas <- list(
  hard_recreationalist = load_persona(get_preset_persona_file(), "Hard_Recreationalist"),
  soft_recreationalist = load_persona(get_preset_persona_file(), "Soft_Recreationalist")
)

### EXTENT
r <- terra::rast("/home/madtig/Desktop/Scotland/Water.tif")
extent <- terra::ext(r)

### DATA dir
data_dir <- "/home/madtig/Desktop/Scotland/"

### RUN THE MODEL
#test
#bush_estate <- get_example_bbox()
#data_dir <- get_example_data_dir()

RP_output_scotland <- list()
for(apersona in 1:length(personas)) {
  RP_output_scotland[apersona] <- compute_potential(personas[[apersona]],
                                                    extent,
                                                    data_dir)
  #test
  # RP_output_scotland[[apersona]] <- compute_potential(personas[[apersona]],
  #                                                   bush_estate,
  #                                                   data_dir)
}
# terra::plot(RP_output_scotland[[2]])
# terra::plot(RP_output_scotland[[1]])
#names
names(RP_output_scotland) <- c("HR", "SR")

#rename layers of HR
names(RP_output_scotland[["HR"]]) <- c(paste0("HR_", names(RP_output_scotland[["HR"]])))
names(RP_output_scotland[["SR"]]) <- c(paste0("SR_", names(RP_output_scotland[["SR"]])))

#glue
scotland_rast <- c(RP_output_scotland$HR, RP_output_scotland$SR)

#write it
terra::writeRaster(scotland_rast,
                   filename = paste0(data_dir, "RP_scotland.tif"),
                   overwrite = TRUE)




