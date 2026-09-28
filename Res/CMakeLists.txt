cmake_minimum_required(VERSION 3.16)

qt_add_qml_module(${MAIN_TARGET_NAME}.Resources
    URI ${MAIN_TARGET_URI}.Resources
    VERSION 1.0
    RESOURCE_PREFIX / # not /qt/qml
    STATIC

    RESOURCES
        "Images/Logo.png"
        "Images/LogoSVG.svg"
        "Images/Logo.svg"
        "Images/defaultUserIcon.svg"

        "Icons/togglePanel.svg"

        "Fonts/Font Awesome 6 Pro-Light-300.otf"
        "Fonts/Font Awesome 6 Pro-Regular-400.otf"
        "Fonts/Font Awesome 6 Pro-Solid-900.otf"
        "Fonts/Font Awesome 6 Pro-Thin-100.otf"

        "Fonts/Inter-Regular.ttf"
        "Fonts/Inter-Medium.ttf"
        "Fonts/Inter-SemiBold.ttf"
        "Fonts/Inter-Bold.ttf"

        "Fonts/JetBrainsMono-Regular.ttf"
        "Fonts/JetBrainsMono-Medium.ttf"
        "Fonts/JetBrainsMono-SemiBold.ttf"
        "Fonts/JetBrainsMono-Bold.ttf"
)
