### DATA dir
data_dir <- "/home/madtig/Desktop/Scotland/"

##### explore it
r <- terra::rast(paste0(data_dir, "RP_scotland.tif"))

r <- r[[c(5,10)]]

#keep only 2 digits
r2  <- round(r, digits = 2)
#the 0s you don't need to show on map
r2 <- terra::classify(r2 , cbind(0, NA))

r2_trimmed <- terra::trim(r2)


#save it
terra::writeRaster(r2_trimmed,
                   filename = paste0(data_dir, "RP_scotland_LITE.tif"),
                   overwrite = TRUE)

r2 <- terra::rast(paste0(data_dir, "RP_scotland_LITE.tif"))

#borders
# scotland_outline <- sf::st_read(paste0(data_dir, "uk_outline/NUTS_Level_1_January_2018_FCB_in_the_United_Kingdom.shp"))
# ext <- terra::as.polygons(terra::ext(r2))

#plot
terra::plot(r2,
            range = c(0,1),
            nc = 2,
            main = c("Hard Recreationalist - RP", "Soft Recreationalist - RP"),
            axes = FALSE, box = TRUE,
            plg = list(x="topright")
            )

