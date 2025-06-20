# File:       app_theme.R
# Package:    biodt.recreation
# Repository: https://github.com/BioDT/uc-ces-recreation
# License:    MIT
# Copyright:  2025 BioDT and the UK Centre for Ecology & Hydrology
# Author(s):  Joe Marsh Rossney

# NOTE: This is modified version of the official UKCEH theme at
# https://github.com/NERC-CEH/UKCEH_shiny_theming/blob/main/theme_elements.R

app_theme <- function() {
    bslib::bs_theme(
        bg = "#fff",
        fg = "#292C2F",
        primary = "#0483A4",
        secondary = "#EAEFEC",
        success = "#37a635",
        info = "#34b8c7",
        warning = "#F49633",
        base_font =
            bslib::font_link(
                family = "Montserrat",
                href = "https://fonts.googleapis.com/css2?family=Montserrat:wght@400;600&display=swap"
            )
    ) |>
        # Increase the font weight of the headings
        bslib::bs_add_variables("headings-font-weight" = 600) |>
        # Make action and download buttons visible again
        # (see https://github.com/NERC-CEH/UKCEH_shiny_theming/issues/5)
        bslib::bs_add_rules("
            .btn {color: black; border-color: darkgrey;}
            .btn.shiny-download-link {color: black; border-color: darkgrey;}
        ")
}

#' @import shiny
app_title_panel <- function(title_text, window_title = title_text) {
    div(
        a(
            href = "https://www.ceh.ac.uk",
            target = "_blank",
            style = "text-decoration: none;", # or image gets underlined
            img(
                src = "https://www.ceh.ac.uk/sites/default/files/images/theme/ukceh_logo_long_720x170_rgb.png", # nolint
                style = "height: 50px;vertical-align:middle;"
            )
        ),
        div(
            style = "
                display: inline-block;
                width: 1px;
                height: 50px;
                background-color: black;
                margin: 0 10px;
                vertical-align: middle;
            "
        ),
        a(
            href = "https://biodt.eu",
            target = "_blank",
            style = "text-decoration: none;",
            img(
                src = "https://biodt.eu/themes/biodt/logo.png",
                style = "height: 60px;vertical-align:middle;"
            )
        ),
        h2(
            title_text,
            style = "vertical-align:middle; display:inline;padding-left:40px;"
        ),
        tagList(
            tags$head(
                tags$title(paste0(window_title, " | UK Centre for Ecology & Hydrology")),
                tags$link(
                    rel = "shortcut icon",
                    href = "https://brandroom.ceh.ac.uk/themes/custom/ceh/favicon.ico"
                )
            )
        ),
        style = "padding: 30px;"
    )
}
