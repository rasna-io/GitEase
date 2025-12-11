cmake_minimum_required(VERSION 3.16)

qt_add_qml_module(${MAIN_TARGET_NAME}.Resources
    URI ${MAIN_TARGET_URI}.Resources
    VERSION 1.0
    RESOURCE_PREFIX / # not /qt/qml
    STATIC

    RESOURCES

)

