# File:       app_ui.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation
# License:    MIT
# Copyright:  2025 BioDT and the UK Centre for Ecology & Hydrology
# Author(s):  Joe Marsh Rossney

get_base_layers <- function() {
    # Wrap this in a function so that it can be accessed from app_server.R!
    list(
        "Street" = "Esri.WorldStreetMap",
        "Topographical" = "Esri.WorldTopoMap",
        "Satellite" = "Esri.WorldImagery",
        "Greyscale" = "Esri.WorldGrayCanvas"
    )
}

#' @import shiny
make_sliders <- function(component) {
    config <- load_config()

    layer_info <- stats::setNames(config[["Description"]], config[["Name"]])
    layer_names <- names(layer_info)
    group_names <- list(
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

    layer_names_this_component <- layer_names[startsWith(layer_names, component)]
    groups_this_component <- group_names[startsWith(names(group_names), component)]

    sliders <- lapply(layer_names_this_component, function(layer_name) {
        sliderInput(
            layer_name,
            label = layer_info[[layer_name]],
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
            h4(group_names[group]),
            fluidRow(
                column(width = 6, sliders_left),
                column(width = 6, sliders_right)
            )
        )
    })
}

#' @import shiny
make_ui <- function() {
    fluidPage(
        theme = app_theme(),
        waiter::use_waiter(),
        fluidRow(
            app_title_panel("Recreational Potential Model for Scotland")
        ),
        sidebarLayout(
            sidebarPanel(
                width = 5,
                tabsetPanel(
                    tabPanel("About", about_html()),
                    tabPanel(
                        "User Guide",
                        p(),
                        tabsetPanel(
                            tabPanel("Create a Persona", persona_html()),
                            tabPanel("Run the Model", model_html()),
                            tabPanel("Adjust the Visualisation", viz_html()),
                            tabPanel("FAQ", faq_html())
                        )
                    ),
                    tabPanel(
                        "Persona",
                        p(),
                        actionButton("loadButton", "Load Persona"),
                        actionButton("saveButton", "Save Persona"),
                        p(),
                        tabsetPanel(
                            tabPanel("Landscape", make_sliders("SLSRA")),
                            tabPanel("Natural Features", make_sliders("FIPS_N")),
                            tabPanel("Infrastructure", make_sliders("FIPS_I")),
                            tabPanel("Water", make_sliders("Water"))
                        )
                    ),
                    tabPanel(
                        "Map Control",
                        p(),
                        h3("Data layers"),
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
                        p(),
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
                        hr(),
                        h3("Base map"),
                        radioButtons(
                            "baseLayerSelect",
                            "Select a base map",
                            choices = get_base_layers(),
                            selected = get_base_layers()[[1]],
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
                div(
                    class = "map-container",
                    style = "position: relative;",
                    leaflet::leafletOutput("map"),
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
        hr(),
        fluidRow(
            column(
                width = 6,
                style = "text-align: left;",
                footer_html()
            ),
            column(
                width = 6,
                style = "text-align: right;",
                copyright_html()
            )
        )
    )
}
