# This is modified version of the official UKCEH theme at
# https://github.com/NERC-CEH/UKCEH_shiny_theming/blob/main/theme_elements.R

custom_theme <- bslib::bs_theme(
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

custom_title_panel <- function(title, window_title = title) {
    shiny::div(
        shiny::a(
            href = "https://www.ceh.ac.uk",
            target = "_blank",
            style = "text-decoration: none;", # or image gets underlined
            shiny::img(
                src = "https://www.ceh.ac.uk/sites/default/files/images/theme/ukceh_logo_long_720x170_rgb.png", # nolint
                style = "height: 50px;vertical-align:middle;"
            )
        ),
        shiny::div(
            style = "
                display: inline-block;
                width: 1px;
                height: 50px;
                background-color: black;
                margin: 0 10px;
                vertical-align: middle;
            "
        ),
        shiny::a(
            href = "https://biodt.eu",
            target = "_blank",
            style = "text-decoration: none;",
            shiny::img(
                src = "https://biodt.eu/themes/biodt/logo.png",
                style = "height: 60px;vertical-align:middle;"
            )
        ),
        shiny::h2(
            title,
            style = "vertical-align:middle; display:inline;padding-left:40px;"
        ),
        shiny::tagList(
            shiny::tags$head(
                shiny::tags$title(paste0(window_title, " | UK Centre for Ecology & Hydrology")),
                shiny::tags$link(
                    rel = "shortcut icon",
                    href = "https://brandroom.ceh.ac.uk/themes/custom/ceh/favicon.ico"
                )
            )
        ),
        style = "padding: 30px;"
    )
}
