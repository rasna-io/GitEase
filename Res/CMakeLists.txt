cmake_minimum_required(VERSION 3.16)

qt_add_qml_module(${MAIN_TARGET_NAME}.Resources
    URI ${MAIN_TARGET_URI}.Resources
    VERSION 1.0
    RESOURCE_PREFIX / # not /qt/qml
    STATIC

    RESOURCES
        "Images/Logo.png"
        "Images/Logo.svg"

        "Fonts/Font Awesome 6 Pro-Light-300.otf"
        "Fonts/Font Awesome 6 Pro-Regular-400.otf"
        "Fonts/Font Awesome 6 Pro-Solid-900.otf"
        "Fonts/Font Awesome 6 Pro-Thin-100.otf"
)
