library(shiny)
library(leaflet)
library(leaflet.extras)

source("content.R")  # contains {content}_html
source("theme.R")  # contains custom_theme, custom_titlePanel

.credentials <- data.frame(
    user = Sys.getenv("APP_USERNAME"),
    password = Sys.getenv("APP_PASSWORD")
)

.persona_dir <- "personas"
.config <- biodt.recreation::load_config()
.layer_info <- setNames(.config[["Description"]], .config[["Name"]])
.layer_names <- names(.layer_info)
.max_area <- 1e9  # about 1/4 of the Cairngorms area
.min_area <- 1e4
.data_extent <- terra::ext(terra::vect(system.file("extdata", "Scotland", "boundaries.shp", package = "biodt.recreation")))

.group_names <- list(
    SLSRA_LCM = "Land Cover",
    SLSRA_Designations = "Official Designations",
    FIPS_N_Landform = "Land Formations",
    FIPS_N_Slope = "Slopes",
    FIPS_N_Soil = "Soil Type",
    FIPS_I_RoadsTracks = "Roads and Tracks",
    FIPS_I_NationalCycleNetwork = "National Cycle Network",
    FIPS_I_LocalPathNetwork = "Local Path Network",
    Water_Lakes = "Lakes",
    Water_Rivers = "Rivers"
)

.base_layers <- list(
    "Street" = "Esri.WorldStreetMap",
    "Topographical" = "Esri.WorldTopoMap",
    "Satellite" = "Esri.WorldImagery",
    "Greyscale" = "Esri.WorldGrayCanvas"
)

list_persona_files <- function() {
    return(list.files(path = .persona_dir, pattern = "\\.csv$", full.names = FALSE))
}

list_users <- function() lapply(list_persona_files(), tools::file_path_sans_ext)

list_personas_in_file <- function(file_name) {
    personas <- names(read.csv(file.path(.persona_dir, file_name), nrows = 1))
    return(personas[personas != "index"])
}

remove_non_alphanumeric <- function(string) {
    string <- gsub(" ", "_", string)  # Spaces to underscore
    string <- gsub("[^a-zA-Z0-9_]+", "", string)  # remove non alpha-numeric
    string <- gsub("^_+|_+$", "", string)  # remove leading or trailing underscores
    return(string)
}

create_sliders <- function(component) {
    layer_names_this_component <- .layer_names[startsWith(.layer_names, component)]
    groups_this_component <- .group_names[startsWith(names(.group_names), component)]

    sliders <- lapply(layer_names_this_component, function(layer_name) {
        sliderInput(
            layer_name,
            label = .layer_info[[layer_name]],
            min = 0,
            max = 10,
            value = 0,
            round = TRUE,
            ticks = FALSE
        )
    })

    lapply(names(groups_this_component), function(group) {
        # NOTE: very hacky method to group all designations, which actually stem
        # from different layers. It may actually be preferable to hard-code the groups
        # into a new column of config.csv
        if (group == "SLSRA_Designations") {
            sliders_this_group <- sliders[!startsWith(layer_names_this_component, "SLSRA_LCM")]
        } else {
            sliders_this_group <- sliders[startsWith(layer_names_this_component, group)]
        }

        n <- length(sliders_this_group)
        sliders_left <- sliders_this_group[seq(1, n, by = 2)]
        sliders_right <- if (n > 1) {
            sliders_this_group[seq(2, n, by = 2)]
        } else {
            list()
        }

        div(
            style = "border: 1px solid #ddd; padding: 10px; border-radius: 5px; margin-top: 5px; margin-bottom: 5px;",
            h4(.group_names[group]),
            fluidRow(
                column(width = 6, sliders_left),
                column(width = 6, sliders_right)
            )
        )
    })
}

palette <- colorNumeric(
    palette = "Spectral",
    reverse = TRUE,
    domain = c(0, 1),
    na.color = "transparent"
)

check_valid_bbox <- function(bbox) {
    if (is.null(bbox)) {
        message("No area has been selected. Please select an area.")
        return(FALSE)
    }
    area <- (terra::xmax(bbox) - terra::xmin(bbox)) * (terra::ymax(bbox) - terra::ymin(bbox))
    if (area > .max_area) {
        message(paste(
            "The area you have selected is too large to be computed at this time",
            "(", sprintf("%.1e", area), ">", .max_area, " m^2 ).",
            "Please draw a smaller area."
        ))
        return(FALSE)
    }
    if (area < .min_area) {
        message(paste(
            "The area you have selected is too small",
            "(", round(area), "<", .min_area, " m^2 ).",
            "Please draw a larger area."
        ))
        return(FALSE)
    }

    entirely_within <- (
        terra::xmin(bbox) > terra::xmin(.data_extent) &&
        terra::xmax(bbox) < terra::xmax(.data_extent) &&
        terra::ymin(bbox) > terra::ymin(.data_extent) &&
        terra::ymax(bbox) < terra::ymax(.data_extent)
    )
    if (entirely_within) {
        message(paste("Selected an area of", sprintf("%.1e", area), "m^2"))
        return(TRUE)
    }

    entirely_outside <- (
        terra::xmin(bbox) > terra::xmax(.data_extent) ||
        terra::xmax(bbox) < terra::xmin(.data_extent) ||
        terra::ymin(bbox) > terra::ymax(.data_extent) ||
        terra::ymax(bbox) < terra::ymin(.data_extent)
    )

    if (entirely_outside) {
        message("Error: The area you have selected is entirely outside the region where we have data.")
        return(FALSE)
    }

    message("Warning: Part of the area you have selected exceeds the boundaries where we have data.")
    return(TRUE)

}

check_valid_persona <- function(persona) {
    if (all(sapply(persona, function(score) score == 0))) {
        message("All the persona scores are zero. At least one score must be non-zero.")
        message("Perhaps you have forgotten to load a persona?")
        return(FALSE)
    }
    return(TRUE)
}

ui <- fluidPage(
    theme = custom_theme,
    waiter::use_waiter(),
    # Add title, contact address and privacy notice in combined title panel + header
    fluidRow(
        custom_titlePanel("Recreational Potential Model for Scotland")
    ),
    sidebarLayout(
        sidebarPanel(
            width = 5,
            tabsetPanel(
                tabPanel("About", about_html),
                tabPanel(
                    "User Guide",
                    tags$p(),
                    tabsetPanel(
                        tabPanel("Create a Persona", persona_html),
                        tabPanel("Run the Model", model_html),
                        tabPanel("Adjust the Visualisation", viz_html),
                        tabPanel("FAQ", faq_html)
                    )
                ),
                tabPanel(
                    "Persona",
                    tags$p(),
                    actionButton("loadButton", "Load Persona"),
                    actionButton("saveButton", "Save Persona"),
                    tags$p(),
                    tabsetPanel(
                        tabPanel("Landscape", create_sliders("SLSRA")),
                        tabPanel("Natural Features", create_sliders("FIPS_N")),
                        tabPanel("Infrastructure", create_sliders("FIPS_I")),
                        tabPanel("Water", create_sliders("Water"))
                    )
                ),
                tabPanel(
                    "Map Control",
                    tags$p(),
                    tags$h3("Data layers"),
                    radioButtons(
                        "layerSelect",
                        "Select which component to display on the map",
                        choices = list(
                            "Landscape" = 1,
                            "Natural Features" = 2,
                            "Infrastructure" = 3,
                            "Water" = 4,
                            "Recreational Potential" = 5
                        ),
                        selected = 5,
                        inline = TRUE
                    ),
                    tags$p(),
                    sliderInput(
                        "minDisplay",
                        "Display values above (values below this will be transparent)",
                        width = 300,
                        min = 0,
                        max = 0.9,
                        value = 0,
                        step = 0.1,
                        ticks = FALSE
                    ),
                    sliderInput(
                        "opacity",
                        "Opacity",
                        width = 300,
                        min = 0,
                        max = 1,
                        value = 1,
                        step = 0.2,
                        ticks = FALSE
                    ),
                    tags$hr(),
                    tags$h3("Base map"),
                    radioButtons(
                        "baseLayerSelect",
                        "Select a base map",
                        choices = .base_layers,
                        selected = .base_layers[[1]],
                        inline = TRUE
                    )
                )
            )
        ),
        mainPanel(
            width = 7,
            tags$head(
                tags$style(HTML("
                    html, body {height: 100%;}
                    #map {height: 80vh !important;}
                    .leaflet-draw-toolbar a {background-color: #e67e00 !important;}
                    .leaflet-draw-toolbar a:hover {background-color: #EAEFEC !important;}
                     #update-button {background-color: #e67e00; border: 5px; border-radius: 5px;}
                ")),
            ),
            tags$div(
                class = "map-container",
                style = "position: relative;",
                leafletOutput("map"),
                absolutePanel(
                    id = "update-button",
                    class = "fab",
                    top = 5,
                    right = 5,
                    bottom = "auto",
                    actionButton("updateButton", "Update Map")
                )
            ),
            verbatimTextOutput("userInfo")
        )
    ),
    tags$hr(),
    fluidRow(
        column(
            width = 6,
            style = "text-align: left;",
            "Information about how we process your data can be found in our ",
            tags$a(href = "https://www.ceh.ac.uk/privacy-notice", "privacy notice.", target = "_blank"),
            tags$br(),
            "Contact: Dr Jan Dick (jand@ceh.ac.uk)."
        ),
        column(
            width = 6,
            style = "text-align: right;",
            "© UK Centre for Ecology & Hydrology and BioDT, 2025."
        )
    )
)

load_dialog <- modalDialog(
    title = "Load Persona",
    selectInput(
        "loadUserSelect",
        "Select user",
        choices = list_users(),
        selected = NULL
    ),
    selectInput(
        "loadPersonaSelect",
        "Select persona",
        choices = NULL,
        selected = NULL
    ),
    actionButton("confirmLoad", "Load"),
    #hr(),
    #fileInput(
    #    "fileUpload",
    #    "Upload a persona file",
    #    accept = c(".csv")
    #),
    footer = tagList(
        modalButton("Cancel"),
    )
)
save_dialog <- modalDialog(
    title = "Save Persona",
    selectInput(
        "saveUserSelect",
        "Existing users: select your user name",
        choices = c("", list_users()),
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
        choices = c("", list_users()),
        selected = ""
    ),
    downloadButton("confirmDownload", "Download"),
    footer = modalButton("Cancel")
)

# Add password authorisation
ui <- shinymanager::secure_app(ui)

server <- function(input, output, session) {
    # Check credentials
    res_auth <- shinymanager::secure_server(
        check_credentials = shinymanager::check_credentials(.credentials)
    )
    output$auth_output <- renderPrint({
        reactiveValuesToList(res_auth)
    })


    get_persona_from_sliders <- function() {
        persona <- sapply(
            .layer_names,
            function(layer_name) input[[layer_name]],
            USE.NAMES = TRUE
        )
        return(persona)
    }

    # Reactive variable to track the selected user
    reactiveUserSelect <- reactiveVal("examples")

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


    # ------------------------------------------------------ Loading

    observeEvent(input$loadButton, {
        updateSelectInput(
            session,
            "loadUserSelect",
            choices = list_users(),
            selected = reactiveUserSelect()
        )
        updateSelectInput(
            session,
            "loadPersonaSelect",
            choices = list_personas_in_file(paste0(reactiveUserSelect(), ".csv"))
        )
        showModal(load_dialog)
    })
    observeEvent(input$loadUserSelect, {
        reactiveUserSelect(input$loadUserSelect)
        updateSelectInput(
            session,
            "loadPersonaSelect",
            choices = list_personas_in_file(paste0(reactiveUserSelect(), ".csv"))
        )
    })
    observeEvent(input$confirmLoad, {
        req(reactiveUserSelect())
        req(input$loadPersonaSelect)

        loaded_persona <- biodt.recreation::load_persona(
            file.path(.persona_dir, paste0(reactiveUserSelect(), ".csv")),
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

        update_user_info(paste0("Loaded persona '", input$loadPersonaSelect, "' from user '", input$loadUserSelect, "'"))  # nolint

        removeModal()
    })
    observeEvent(input$fileUpload, {
        tryCatch({
            . <- biodt.recreation::read_persona_csv(input$fileUpload$datapath)  # nolint
        }, error = function(e) {
            update_user_info("Unable to read persona file.")
            return()
        })

        user_name <- remove_non_alphanumeric(tools::file_path_sans_ext(basename(input$fileUpload$name)))
        save_path <- file.path(.persona_dir, paste0(user_name, ".csv"))
        update_user_info(paste("Attempting to save uploaded persona file, user name:", user_name))

        if (file.exists(save_path)) {
            append_user_info(paste("A persona file with this name already exists. Please rename the file and try again."))  # nolint
            return()
        }

        file.copy(input$fileUpload$datapath, save_path, overwrite = FALSE)

        # Refresh the options displayed in the select user/persona dialog
        reactiveUserSelect(user_name)
        updateSelectInput(
            session,
            "loadUserSelect",
            choices = list_users(),
            selected = reactiveUserSelect()
        )
        updateSelectInput(
            session,
            "loadPersonaSelect",
            choices = list_personas_in_file(paste0(reactiveUserSelect(), ".csv"))
        )
    })

    # ------------------------------------------------------ Saving

    observeEvent(input$saveButton, {
        updateSelectInput(
            session,
            "saveUserSelect",
            choices = c("", list_users()),
            selected = ""
        )
        updateSelectInput(
            session,
            "downloadUserSelect",
            choices = c("", list_users()),
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
        user_name <- remove_non_alphanumeric(user_name)
        persona_name <- remove_non_alphanumeric(persona_name)

        if (user_name == "examples") {
            # TODO: display message inside modal, so it's visible
            message <- "Cannot save personas to 'examples'. Please choose a different user name"
            update_user_info(message)
            return()
        }

        message <- paste0("Saving persona '", persona_name, "' under user '", user_name, "'")

        captured_messages <- capture.output(
            biodt.recreation::save_persona(
                persona = get_persona_from_sliders(),
                csv_path = file.path(.persona_dir, paste0(user_name, ".csv")),
                name = persona_name
            ),
            type = "message"
        )
        update_user_info(paste(c(message, captured_messages), collapse = "\n"))

        removeModal()

    })
    output$confirmDownload <- downloadHandler(
        filename = function() paste0(input$downloadUserSelect, ".csv"),
        content = function(file) {
            src <- file.path(.persona_dir, paste0(input$downloadUserSelect, ".csv"))
            file.copy(src, file)
            removeModal()
        }
    )

    # --------------------------------------------------------------- Map
    # Initialize Leaflet map
    output$map <- renderLeaflet({
        addBaseLayers <- function(map) {
            for (layer in .base_layers) {
                map <- addProviderTiles(map, layer, group = layer)
            }
            return(map)
        }
        leaflet() |>
            setView(lng = -4.2026, lat = 56.4907, zoom = 7) |>
            addBaseLayers() |>
            hideGroup(.base_layers) |>
            showGroup(.base_layers[[1]]) |>
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

        msg <- capture.output(
            check_valid_bbox(extent_27700),
            type = "message"
        )
        update_user_info(msg)
    })

    # Recompute raster when update button is clicked
    observeEvent(input$updateButton, {
        persona <- get_persona_from_sliders()

        msg <- capture.output(
            valid_persona <- check_valid_persona(persona),
            type = "message"
        )
        userInfoText(paste(msg, collapse = "\n"))

        if (!valid_persona) return()

        bbox <- reactiveExtent()

        msg <- capture.output(
            valid_bbox <- check_valid_bbox(bbox),
            type = "message"
        )
        update_user_info(msg)
        if (!valid_bbox) return()

        waiter::waiter_show(
            html = div(
                style = "color: #F0F0F0;",
                tags$h3("Computing Recreational Potential..."),
                waiter::spin_fading_circles()
            ),
            color = "rgba(50, 50, 50, 0.6)"
        )

        msg <- capture.output(
            layers <- biodt.recreation::compute_potential(
                persona,
                bbox = bbox
            ),
            type = "message"
        )
        userInfoText(paste(msg, collapse = "\n"))

        # Update reactiveLayers with new raster
        reactiveLayers(layers)

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

    # NOTE: this did not work. Using leafletProxy is the issue.
    # Need to create a fresh map object.
    # See https://forum.posit.co/t/solved-error-when-using-mapshot-with-shiny-leaflet/6765/7
    #
    #output$downloadMap <- downloadHandler(
    #    filename = function() {
    #        paste("map_", Sys.Date(), ".png", sep = "")
    #    },
    #    content = function(file) {
    #        mapview::mapshot2(
    #            leafletProxy("map"),
    #            file = file,
    #            cliprect = "viewport"
    #        )
    #    }
    #)
}

shinyApp(ui = ui, server = server)
