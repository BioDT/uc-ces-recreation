
#' @title is_all_na
#' @description checking if all NAs in spatraster
#' @param r a SpatRaster object
is_all_na <- function(r) {
  all(is.na(terra::values(r)))
}

#' @title make_layer_map
#' @description Create a leaflet map with raster layers
make_layer_map <- function(rstack, base_map, show_index = 1, color = "orange") {
  
  valid_layers <- which(!sapply(1:terra::nlyr(rstack),
                                function(i) is_all_na(rstack[[i]])))
  
  wanted_layers <- names(rstack[[valid_layers]])
  display_names <- gsub("_", " ", wanted_layers)
  names(wanted_layers) <- display_names
  
  initial_group <- display_names[show_index]
  hidden_groups <- setdiff(display_names, initial_group)
  
  pal <- leaflet::colorFactor(c("transparent", color), domain = c(0, 1), na.color = "transparent")
  
  map <- base_map
  for (disp_name in names(wanted_layers)) {
    layer <- rstack[[wanted_layers[disp_name]]]
    map <- map %>% leaflet::addRasterImage(layer, colors = pal, opacity = 0.8, group = disp_name)
  }
  
  map <- map %>%
    leaflet::addLayersControl(
      baseGroups = c("Streets", "Satellite"),
      overlayGroups = display_names,
      options = leaflet::layersControlOptions(collapsed = FALSE)
    ) %>%
    leaflet::addLegend(pal = pal, values = c(0, 1), title = "Values",  position = "bottomleft")
  
  for (grp in hidden_groups) {
    map <- map %>% leaflet::hideGroup(grp)
  }
  
  return(map)
}

#' @title make_layer_map
#' @description Create a leaflet map with raster layers for the distance components
make_layer_map_dist <- function(rstack, base_map, show_index = 1, color_original = "orange"){
  
  # Append suffix to layer names for each element in the list
  rstack <- lapply(names(rstack), function(nm) {
    raster_obj <- rstack[[nm]]
    # Append suffix, e.g. "_original", "_distance", "_scored" based on the list name
    suffix <- paste0("_", nm)
    names(raster_obj) <- paste0(names(raster_obj), suffix)
    return(raster_obj)
  })
  
  # Fix names back to list
  names(rstack) <- c("original", "distance", "scored")
  
  #layers that are not all NAs
  valid_layers <- lapply(rstack, function(rs) {
    which(!sapply(1:terra::nlyr(rs), function(i) is_all_na(rs[[i]])))
  })
  
  wanted_layers <- mapply(function(rs, vl) {
    names(rs[[vl]])
  }, rstack, valid_layers, SIMPLIFY = FALSE)
  
  # Create display names for each layer  
  display_names <- lapply(wanted_layers, function(wl) {
    gsub("_", " ", wl)
  })
  
  
  # Create palettes
  pal_original <- leaflet::colorFactor(
    c("transparent", color_original),
    domain = c(0, 1),
    na.color = "transparent"
  )
  
  global_min_distance <- min(terra::minmax(rstack[["distance"]][[valid_layers[["distance"]] ]] )[1, ])
  global_max_distance <- max(terra::minmax(rstack[["distance"]][[valid_layers[["distance"]] ]] )[2, ])
  
  viridis_pal_distance <- leaflet::colorNumeric(
    palette = "magma",
    domain = c(global_min_distance, global_max_distance),
    na.color = "transparent", reverse = TRUE)
    
  global_min_scored <- min(terra::minmax(rstack[["scored"]][[valid_layers[["scored"]] ]] )[1, ])
  global_max_scored <- max(terra::minmax(rstack[["scored"]][[valid_layers[["scored"]] ]] )[2, ])
    
  viridis_pal_scored <- leaflet::colorNumeric(
    palette = "viridis",
    domain = c(global_min_scored, global_max_scored),
    na.color = "transparent")
  
  
  #groups
  all_groups <- c(display_names[["original"]], display_names[["distance"]],display_names[["scored"]] )
  initial_group <- c(display_names[["original"]][show_index], 
                     display_names[["distance"]][show_index],
                     display_names[["scored"]][show_index])
  hidden_groups <- setdiff(all_groups, initial_group)
  
  map <- base_map
  
  #add the distance data
  for ( alayer in 1:length(wanted_layers[["distance"]] )) {
    layer <- rstack[["distance"]][wanted_layers[["distance"]][alayer]]
    map <- map %>%
      leaflet::addRasterImage(layer, colors = viridis_pal_distance, opacity = 0.6, group = display_names[["distance"]][alayer])
  } 
  
  #add the scored data
  for ( alayer in 1:length(wanted_layers[["scored"]] )) {
    layer <- rstack[["scored"]][wanted_layers[["scored"]][alayer]]
    map <- map %>%
      leaflet::addRasterImage(layer, colors = viridis_pal_scored, opacity = 0.6, group = display_names[["scored"]][alayer])
  } 
  
  #add the original data
  for ( alayer in 1:length(wanted_layers[["original"]] )) {
    layer <- rstack[["original"]][wanted_layers[["original"]][alayer]]
    map <- map %>%
      leaflet::addRasterImage(layer, colors = pal_original, opacity = 1, group = display_names[["original"]][alayer])
  } 
  
  # Add layers control
  map <- map %>%
    leaflet::addLayersControl(
      baseGroups = c("Streets", "Satellite"),
      overlayGroups = sort(all_groups),
      options = leaflet::layersControlOptions(collapsed = FALSE)
    )
  
  # Add legends
  map <- map %>%
    #oringinal
    leaflet::addLegend(pal = pal_original, values = c(0, 1), title = "If present:",  position = "bottomleft") %>%
    #distance
    leaflet::addLegend(pal = viridis_pal_distance, values = c(global_min_distance, global_max_distance), title = "Distance (m)", position = "bottomleft") %>%
    #scored
    leaflet::addLegend(pal = viridis_pal_scored, values = c(global_min_scored, global_max_scored), title = "Score", position = "bottomleft")
  
  # Hide all groups except the one indicated
  for (grp in hidden_groups) {
    map <- map %>% leaflet::hideGroup(grp)
  }
  
  return(map)

}


#' @title summarise_persona_scores
#' @description summarise persona preferences
summarise_persona_scores <- function(persona) {
  description <- read.csv(here::here("inst", "extdata", "config", "config.csv"))
  
  persona %>%
    merge(description, by = "Name", all.x = TRUE) %>%
    dplyr::select(Score, Name, Description, Component) %>%
    dplyr::arrange(desc(Score)) %>%
    dplyr::mutate(
      feature = paste(Description, " (", Component, ")", sep = "")
    ) %>%
    dplyr::filter(Score >= 8 | Score <= 2) %>%
    dplyr::mutate(score_group = dplyr::case_when(
      Score >= 9 ~ "highest scores (scored 10 or 9)",
      Score <= 1 ~ "lowest scores (scored 0 or 1)"
    )) %>%
    dplyr::group_by(score_group) %>%
    dplyr::summarise(
      features = paste(feature, collapse = ", "),
      .groups = "drop"
    ) %>%
    na.omit()
  
}

#' @title build_rp_map
#' @description make leaflet from output of RP model
build_rp_map <- function(base_map, RP_output) {

  # Color palette matching the shiny app
  palette_RP <- leaflet::colorNumeric(
    palette = "Spectral",
    reverse = TRUE,
    domain = c(0, 1),
    na.color = "transparent"
  )
  

  map <- base_map %>%

    # Add raster layers
    leaflet::addRasterImage(RP_output[[5]], colors = palette_RP, opacity = 0.8, group = "Recreational Potential") %>%
    leaflet::addRasterImage(RP_output[[1]], colors = palette_RP, opacity = 0.8, group = "Landscape component") %>%
    leaflet::addRasterImage(RP_output[[2]], colors = palette_RP, opacity = 0.8, group = "Natural features component") %>%
    leaflet::addRasterImage(RP_output[[3]], colors = palette_RP, opacity = 0.8, group = "Infrastructure component") %>%
    leaflet::addRasterImage(RP_output[[4]], colors = palette_RP, opacity = 0.8, group = "Water component") %>%
    
    # Layer controls
    leaflet::addLayersControl(
      baseGroups = c("Streets", "Satellite"),
      overlayGroups = c(
        "Recreational Potential",
        "Landscape component",
        "Natural features component",
        "Infrastructure component",
        "Water component"
      ),
      options = leaflet::layersControlOptions(collapsed = FALSE)
    ) %>%
    
    # Legend
    leaflet::addLegend(
      pal = palette_RP,
      values = c(0, 1),
      title = "RP score",
      position = "bottomleft"
    ) %>%
    
    # Hide additional component layers by default
    leaflet::hideGroup(c(
      "Landscape component",
      "Natural features component",
      "Infrastructure component",
      "Water component"
    ))
  
  return(map)
}
