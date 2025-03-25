library(shiny)
library(leaflet)
library(leaflet.extras)

source("content.R") # contains {content}_html
source("theme.R") # contains custom_theme, custom_titlePanel

.persona_dir <- file.path(rprojroot::find_root(rprojroot::is_r_package), "personas")
.config <- biodt.recreation::load_config()
.layer_info <- stats::setNames(.config[["Description"]], .config[["Name"]])
.layer_names <- names(.layer_info)

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
    # hr(),
    # fileInput(
    # "fileUpload",
    # "Upload a persona file",
    # accept = c(".csv")
    # ),
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
