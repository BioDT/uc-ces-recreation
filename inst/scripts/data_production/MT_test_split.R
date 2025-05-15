
#############################################
####### split the raster in n sections ######
# returns a list of tiles
#############################################

split_raster_with_buffer <- function(r, target_tiles, buffer_dist) {
  
  # 1) check format
  if (!inherits(r, "SpatRaster")) {
    stop("Input must be a 'SpatRaster' object from the terra package.")
  }
  
  # 2) split in tiles
  
  nrow_ras <- nrow(r)
  ncol_ras <- ncol(r)
  
  aspect <- ncol_ras / nrow_ras
  ncols <- ceiling(sqrt(target_tiles * aspect))
  nrows <- ceiling(target_tiles / ncols)

  message("Will split into ", nrows * ncols, " tiles (", nrows, " rows × ", ncols, " cols)")
  
  e <- terra::ext(r)
  tile_width  <- (e[2] - e[1]) / ncols
  tile_height <- (e[4] - e[3]) / nrows
  
  tiles <- vector("list", length = ncols * nrows)
  k <- 1
  for (i in 0:(ncols - 1)) {
    for (j in 0:(nrows - 1)) {
      xmin <- e[1] + i * tile_width
      xmax <- xmin + tile_width
      ymin <- e[3] + j * tile_height
      ymax <- ymin + tile_height
      orig_extent <- terra::ext(xmin, xmax, ymin, ymax)
      
      # Edge checks
      on_left   <- i == 0
      on_right  <- i == (ncols - 1)
      on_bottom <- j == 0
      on_top    <- j == (nrows - 1)
      
      xmin_buf <- if (!on_left)  xmin - buffer_dist else xmin
      xmax_buf <- if (!on_right) xmax + buffer_dist else xmax
      ymin_buf <- if (!on_bottom) ymin - buffer_dist else ymin
      ymax_buf <- if (!on_top)    ymax + buffer_dist else ymax
      
      buf_extent <- terra::ext(xmin_buf, xmax_buf, ymin_buf, ymax_buf)
      
      # Store both extents in a named list
      tiles[[k]] <- list(
        buffer = buf_extent,
        original = orig_extent
      )
      k <- k + 1
    }
  }
  
  #end
  return(tiles)
}



#############################################
####### re-crop to original tiles size ######
# returns cropped tile
#############################################
crop_to_original_extent <- function(raster, tile_info) {
  
  #check format
  if (!inherits(raster, "SpatRaster")) {
    stop("'raster' must be a SpatRaster")
  }
  
  if (!is.list(tile_info) || is.null(tile_info$original)) {
    stop("'tile_info' must be a list with an 'original' element containing an extent.")
  }
  
  return(terra::crop(raster, tile_info$original))
}



##############################################
#########    test splitting  #############
##############################################
test_raster_path <-"~/Desktop/repositories/uc-ces-recreation2/inst/extdata/rasters/Stage_3/Water.tif" 
#test_raster_path <-"~/Desktop/repositories/uc-ces-recreation2/inst/extdata/rasters/Bush/Water.tif" 

r <- terra::rast(test_raster_path)

buffer_dist <- 10000  #in m

tiles <- split_raster_with_buffer(r = r, target_tiles = 20 , buffer_dist = buffer_dist) #target tiles is approximate as it must be able to divide them equally etc..


###### calculate distance for each chunck

output_files <- character(length(tiles))
original_layer_names <- names(r)

for (i in seq_along(tiles)) {
  
  message("Processing tile ", i, "/", length(tiles))
  
  tile_info <- tiles[[i]]
  chunk <- terra::crop(r, tile_info$buffer)
  
  # Initialize list to hold processed distance layers
  dist_layers <- vector("list", length = length(original_layer_names))
  names(dist_layers) <- original_layer_names
  
  for (layer_idx in seq_along(original_layer_names)) {
    layer_name <- original_layer_names[layer_idx]
    
    if (layer_name %in% names(chunk)) {
      lyr <- chunk[[layer_name]]
      
      has_values <- terra::global(lyr, fun = function(x) any(!is.na(x)))[[1]]
      
      if (has_values) {
        # Compute distance for this layer
        dist_layer <- terra::distance(lyr, target = NA, unit = "m", method = "haversine")
        dist_layers[[layer_name]] <- dist_layer
        
      } else {
        # Replace with empty raster matching layer extent and resolution
        empty_ras <- terra::rast(lyr)
        terra::values(empty_ras) <- NA
        dist_layers[[layer_name]] <- empty_ras
      }
    } else {
      
      # Layer not present (e.g. cropped out), use empty raster
      lyr_template <- terra::crop(r[[layer_name]], tile_info$buffer)
      terra::values(lyr_template) <- NA
      dist_layers[[layer_name]] <- lyr_template
    }
  }
  
  # Stack layers back into a SpatRaster
  dist_ras <- terra::rast(dist_layers)
  names(dist_ras) <- original_layer_names
  
  # Crop back to original (non-buffered) extent
  dist_ras_cropped <- crop_to_original_extent(dist_ras, tile_info)
  
  # Save to file
  outfile <- paste0("tile_dist_", i, ".tif")
  if (file.exists(outfile)) file.remove(outfile)
  terra::writeRaster(dist_ras_cropped, outfile, overwrite = TRUE)
  output_files[i] <- outfile
}

##### re adding them
message("re-adding them all", i, "/", length(tiles))
rasters <- lapply(output_files, terra::rast)
full_distance_raster <- do.call(terra::mosaic, rasters)
names(full_distance_raster) <- original_layer_names

terra::writeRaster(full_distance_raster, "full_distance_result.tif", overwrite = TRUE)

file.remove(output_files)

#show <- terra::rast("full_distance_result_bush.tif")
#terra::plot(show)



################ test with original function ############
compute_distance <- function(infile, outfile) {
  raster <- terra::rast(infile)
  
  ##### check if there are "empty layers" in the selected area - if so, exclude them
  empty_layers <- c()
  for (i in 1:terra::nlyr(raster)) {
    #stops as soon as it find 1 value that is not NA and moves on
    non_na_found <- terra::global(raster[[i]], fun = function(x) any(!is.na(x)))[[1]]
    if (!non_na_found) {
      empty_layers <- c(empty_layers, names(raster)[i])
    }
  }
  if (length(empty_layers) > 0){
    print(paste("excluding layers", empty_layers, "because they seem empty"))
    raster <- raster[[!names(raster) %in% empty_layers]]
  }
  
  # ##### check if there are "completely full" layers, if so, they all need to be 1
  # full_layers <- c()
  # for (i in 1:terra::nlyr(raster)) {
  #   # Check if all values are NOT NA (i.e., fully populated layer)
  #   all_non_na <- terra::global(raster[[i]], fun = function(x) all(!is.na(x)))[[1]]
  #   if (all_non_na) {
  #     full_layers <- c(full_layers, names(raster)[i])
  #   }
  # }
  # if (length(full_layers) > 0) {
  #   print(paste("excluding layers", full_layers, "because they are 100% full (no NAs)"))
  #   raster <- raster[[!names(raster) %in% full_layers]]
  # }
  
  ## the layers that have both Nas and Numbers can have the distance calculated
  # terra::distance takes every single NA and assigns that cell a value that's the distance to the nearest 1.
  #The cells that are 1 get assigned 0.
  
  # check_layers <- function(r) {
  #   sapply(1:terra::nlyr(r), function(i) {
  #     lyr <- r[[i]]
  #     v <- terra::values(lyr, mat = FALSE)
  #     all(is.na(v) | v == 1)
  #   })
  # }
  # all_layers_valid <- all(check_layers(raster))
  
  terra::distance(
    raster,
    target = NA, # targets everything excluding the features (v expensive!)
    unit = "m",
    method = "haversine",
    filename = outfile,
    datatype = "FLT4S",
    overwrite = TRUE
  )
  
}

#infile <- test_raster_path
#outfile <- "full_distance_check.tif"
#compute_distance(infile = infile,
#                 outfile= outfile)

#show_check <- terra::rast("full_distance_check.tif")
#terra::plot(show_check)
