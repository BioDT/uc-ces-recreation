# File:       app_server.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation2
# License:    MIT
# Copyright:  2025 BioDT
# Author(s):  Joe Marsh Rossney

palette <- colorNumeric(
    palette = "Spectral",
    reverse = TRUE,
    domain = c(0, 1),
    na.color = "transparent"
)

list_users <- function(persona_dir) {
    lapply(list_csv_files(persona_dir), tools::file_path_sans_ext)
}

#' @import shiny
make_load_dialog <- function(persona_dir) {
    modalDialog(
        title = "Load Persona",
        selectInput(
            "loadUserSelect",
            "Select user",
            choices = list_users(persona_dir),
            selected = NULL
        ),
        selectInput(
            "loadPersonaSelect",
            "Select persona",
            choices = NULL,
            selected = NULL
        ),
        actionButton("confirmLoad", "Load"),
        hr(),
        fileInput(
            "fileUpload",
            "Upload a persona file",
            accept = c(".csv")
        ),
        footer = tagList(
            modalButton("Cancel"),
        )
    )
}

#' @import shiny
make_save_dialog <- function(persona_dir) {
    modalDialog(
        title = "Save Persona",
        selectInput(
            "saveUserSelect",
            "Existing users: select your user name",
            choices = c("", list_users(persona_dir)),
            selected = ""
        ),
        textInput("saveUserName", "New users: enter a user name"),
        textInput(
            "savePersonaName",
            "Enter a unique name for the persona",
            value = NULL
        ),
        actionButton("confirmSave", "Save"),
        hr(),
        selectInput(
            "downloadUserSelect",
            "Download persona File",
            choices = c("", list_users(persona_dir)),
            selected = ""
        ),
        downloadButton("confirmDownload", "Download"),
        footer = modalButton("Cancel")
    )
}

#' @import leaflet
#' @import leaflet.extras
#' @import shiny
make_server <- function(persona_dir = NULL, data_dir = NULL) {
    config <- load_config()
    layer_names <- config[["Name"]]

    if (is.null(persona_dir)) {
        persona_dir <- system.file("extdata", package = "biodt.recreation")
    }
    if (is.null(data_dir)) {
        data_dir <- get_default_data_dir()
    }

    server <- function(input, output, session) {
        # Reactive variable to track the selected user
        reactiveUserSelect <- reactiveVal("example_personas")

        # Reactive variable for caching computed raster
        reactiveLayers <- reactiveVal()

        # Reactive variable for coordinates of user-drawn bbox
        reactiveExtent <- reactiveVal()

        # Reactive variable for displaying info to user
        userInfoText <- reactiveVal("")

        output$userInfo <- renderText({
            userInfoText()
        })

        clear_user_info <- function() userInfoText("")

        update_user_info <- function(message) {
            clear_user_info()
            userInfoText(message)
        }

        append_user_info <- function(message) {
            userInfoText(paste(c(userInfoText(), message), collapse = "\n"))
        }

        get_persona_from_sliders <- function() {
            persona <- sapply(
                layer_names,
                function(layer_name) input[[layer_name]],
                USE.NAMES = TRUE
            )
            return(persona)
        }

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
        # Loading                                   #
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

        load_dialog <- make_load_dialog(persona_dir)

        observeEvent(input$loadButton, {
            updateSelectInput(
                session,
                "loadUserSelect",
                choices = list_users(persona_dir),
                selected = reactiveUserSelect()
            )
            updateSelectInput(
                session,
                "loadPersonaSelect",
                choices = list_personas_in_file(
                    file.path(persona_dir, paste0(reactiveUserSelect(), ".csv"))
                )
            )
            showModal(load_dialog)
        })
        observeEvent(input$loadUserSelect, {
            reactiveUserSelect(input$loadUserSelect)
            updateSelectInput(
                session,
                "loadPersonaSelect",
                choices = list_personas_in_file(
                    file.path(persona_dir, paste0(reactiveUserSelect(), ".csv"))
                )
            )
        })
        observeEvent(input$confirmLoad, {
            req(reactiveUserSelect())
            req(input$loadPersonaSelect)

            loaded_persona <- load_persona(
                file.path(persona_dir, paste0(reactiveUserSelect(), ".csv")),
                input$loadPersonaSelect
            )
            # Apply new persona to sliders
            lapply(names(loaded_persona), function(layer_name) {
                updateSliderInput(
                    session,
                    inputId = layer_name,
                    value = loaded_persona[[layer_name]]
                )
            })

            update_user_info(paste0("Loaded persona '", input$loadPersonaSelect, "' from user '", input$loadUserSelect, "'")) # nolint

            removeModal()
        })
        observeEvent(input$fileUpload, {
            tryCatch(
                {
                    . <- read_persona_csv(input$fileUpload$datapath) # nolint
                },
                error = function(e) {
                    update_user_info("Unable to read persona file.")
                    return()
                }
            )

            user_name <- make_safe_string(tools::file_path_sans_ext(basename(input$fileUpload$name)))
            save_path <- file.path(persona_dir, paste0(user_name, ".csv"))
            update_user_info(paste("Attempting to save uploaded persona file, user name:", user_name))

            if (file.exists(save_path)) {
                append_user_info(paste("A persona file with this name already exists. Please rename the file and try again.")) # nolint
                return()
            }

            file.copy(input$fileUpload$datapath, save_path, overwrite = FALSE)

            # Refresh the options displayed in the select user/persona dialog
            reactiveUserSelect(user_name)
            updateSelectInput(
                session,
                "loadUserSelect",
                choices = list_users(persona_dir),
                selected = reactiveUserSelect()
            )
            updateSelectInput(
                session,
                "loadPersonaSelect",
                choices = list_personas_in_file(
                    file.path(persona_dir, paste0(reactiveUserSelect(), ".csv"))
                )
            )
        })

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
        # Saving                                    #
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

        save_dialog <- make_save_dialog(persona_dir)

        observeEvent(input$saveButton, {
            updateSelectInput(
                session,
                "saveUserSelect",
                choices = c("", list_users(persona_dir)),
                selected = ""
            )
            updateSelectInput(
                session,
                "downloadUserSelect",
                choices = c("", list_users(persona_dir)),
                selected = ""
            )
            showModal(save_dialog)
        })
        observeEvent(input$confirmSave, {
            req(input$savePersonaName)
            req(nzchar(input$saveUserSelect) || nzchar(input$saveUserName))

            user_name <- if (input$saveUserName != "") input$saveUserName else input$saveUserSelect
            persona_name <- input$savePersonaName

            # Remove characters that may cause problems with i/o and dataframe filtering
            user_name <- make_safe_string(user_name)
            persona_name <- make_safe_string(persona_name)

            if (user_name == "examples") {
                # TODO: display message inside modal, so it's visible
                message <- "Cannot save personas to 'examples'. Please choose a different user name"
                update_user_info(message)
                return()
            }

            message <- paste0("Saving persona '", persona_name, "' under user '", user_name, "'")

            extra_messages <- capture_messages(
                save_persona(
                    persona = get_persona_from_sliders(),
                    csv_path = file.path(persona_dir, paste0(user_name, ".csv")),
                    name = persona_name
                )
            )
            update_user_info(paste(c(message, extra_messages), collapse = "\n"))

            removeModal()
        })
        output$confirmDownload <- downloadHandler(
            filename = function() paste0(input$downloadUserSelect, ".csv"),
            content = function(file) {
                src <- file.path(persona_dir, paste0(input$downloadUserSelect, ".csv"))
                file.copy(src, file)
                removeModal()
            }
        )

        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
        # Map                                       #
        # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

        # Initialize Leaflet map
        output$map <- renderLeaflet({
            base_layers <- get_base_layers()
            addBaseLayers <- function(map) {
                for (layer in base_layers) {
                    map <- addProviderTiles(map, layer, group = layer)
                }
                return(map)
            }
            leaflet() |>
                setView(lng = -4.2026, lat = 56.4907, zoom = 7) |>
                addBaseLayers() |>
                hideGroup(base_layers) |>
                showGroup(base_layers[[1]]) |>
                addLegend(
                    title = "Values",
                    position = "bottomright",
                    values = c(0, 1),
                    pal = palette
                ) |>
                addFullscreenControl() |>
                addDrawToolbar(
                    targetGroup = "drawnItems",
                    singleFeature = TRUE,
                    rectangleOptions = drawRectangleOptions(
                        shapeOptions = drawShapeOptions(
                            color = "black",
                            weight = 2,
                            fillOpacity = 0
                        )
                    ),
                    polylineOptions = FALSE,
                    polygonOptions = FALSE,
                    circleOptions = FALSE,
                    markerOptions = FALSE,
                    circleMarkerOptions = FALSE
                )
        })

        # Grabs cached layers and updates map with current layer selection
        update_map <- function() {
            req(reactiveLayers())

            clear_user_info()

            waiter::waiter_show(
                html = div(
                    style = "color: #F0F0F0;",
                    tags$h3("Updating Map..."),
                    waiter::spin_fading_circles()
                ),
                color = "rgba(50, 50, 50, 0.6)"
            )

            layers <- reactiveLayers()
            curr_layer <- layers[[as.numeric(input$layerSelect)]]

            if (input$minDisplay > 0) {
                curr_layer <- terra::ifel(curr_layer > input$minDisplay, curr_layer, NA)
            }

            if (all(is.na(terra::values(curr_layer)))) {
                update_user_info("There are no numeric values in this data. Nothing will be displayed.")
            }

            leafletProxy("map") |>
                clearImages() |>
                addRasterImage(curr_layer, colors = palette, opacity = input$opacity)

            waiter::waiter_hide()
        }

        observeEvent(input$baseLayerSelect, {
            leafletProxy("map") |>
                hideGroup(c("Esri.WorldStreetMap", "Esri.WorldTopoMap", "Esri.WorldImagery", "Esri.WorldGrayCanvas")) |>
                showGroup(input$baseLayerSelect)
            update_map()
        })

        # Draw rectangle
        # NOTE: input$map_draw_new_feature automatically created by leaflet.extras
        # when using addDrawToolbar()
        observeEvent(input$map_draw_new_feature, {
            bbox <- input$map_draw_new_feature

            stopifnot(bbox$geometry$type == "Polygon")

            # This is pretty hacky - must be a cleaner way...
            coords <- bbox$geometry$coordinates[[1]]
            lons <- unlist(sapply(coords, function(coord) coord[1]))
            lats <- unlist(sapply(coords, function(coord) coord[2]))
            xmin <- min(lons)
            xmax <- max(lons)
            ymin <- min(lats)
            ymax <- max(lats)

            # Fit the map to these bounds
            leafletProxy("map") |>
                fitBounds(lng1 = xmin, lat1 = ymin, lng2 = xmax, lat2 = ymax)

            # These coords are in EPSG:4326, but our rasters are EPSG:27700
            extent_4326 <- terra::ext(xmin, xmax, ymin, ymax)
            extent_27700 <- terra::project(extent_4326, from = "EPSG:4326", to = "EPSG:27700")

            # Store the SpatExtent as a reactive value
            reactiveExtent(extent_27700)

            valid_bbox_check <- check_valid_bbox(extent_27700)
            update_user_info(valid_bbox_check$message)
        })

        # Recompute raster when update button is clicked
        observeEvent(input$updateButton, {
            persona <- get_persona_from_sliders()
            bbox <- reactiveExtent()

            valid_persona_check <- check_valid_persona(persona)
            update_user_info(valid_persona_check$message)
            if (is_error(valid_persona_check$result)) {
                return()
            }

            valid_bbox_check <- check_valid_bbox(bbox)
            update_user_info(valid_bbox_check$message)
            if (is_error(valid_bbox_check$result)) {
                return()
            }

            waiter::waiter_show(
                html = div(
                    style = "color: #F0F0F0;",
                    h3("Computing Recreational Potential..."),
                    waiter::spin_fading_circles()
                ),
                color = "rgba(50, 50, 50, 0.6)"
            )

            output <- capture_messages(errors_as_messages(compute_potential))(persona, data_dir, bbox = bbox)
            update_user_info(output$message)
            if (is_error(output$result)) {
                return()
            }

            # Update reactiveLayers with computed raster
            reactiveLayers(output$result)

            waiter::waiter_hide()

            update_map()
        })

        # Update map using cached values when layer selection changes
        observeEvent(input$layerSelect, {
            update_map()
        })

        # Update map using cached values when opacity changes
        observeEvent(input$opacity, {
            update_map()
        })

        # Update map using cached values when lower threshold changes
        observeEvent(input$minDisplay, {
            update_map()
        })
    }

    return(server)
}
