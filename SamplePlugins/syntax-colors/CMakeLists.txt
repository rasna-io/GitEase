cmake_minimum_required(VERSION 3.16)
project(SyntaxColorsPlugin VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick)

if(NOT DEFINED GITEASE_SDK_DIR OR GITEASE_SDK_DIR STREQUAL "")
    get_filename_component(GITEASE_SDK_DIR
        "${CMAKE_CURRENT_SOURCE_DIR}/../../Src/Plugins"
        ABSOLUTE)
endif()

if(NOT EXISTS "${GITEASE_SDK_DIR}/IPlugin.h")
    message(FATAL_ERROR
        "GitEase SDK not found at: ${GITEASE_SDK_DIR}\n"
        "Pass -DGITEASE_SDK_DIR=<absolute/path/to/GitEase/Src/Plugins>.")
endif()

add_library(syntax-colors-plugin SHARED
    SyntaxColorsPlugin.h
    SyntaxColorsPlugin.cpp
    SyntaxColorizer.h
    SyntaxColorizer.cpp
    Tokenizer.h
    Tokenizer.cpp
    Languages.h
    Languages.cpp
)

set_target_properties(syntax-colors-plugin PROPERTIES
    PREFIX ""
)

qt_add_resources(syntax-colors-plugin "syntax_colors_qml"
    PREFIX "/com.gitease.syntax-colors"
    FILES
        qml/Colorizer.qml
)

target_include_directories(syntax-colors-plugin PRIVATE
    ${GITEASE_SDK_DIR}
)

target_link_libraries(syntax-colors-plugin PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Quick
)

if(NOT GITEASE_PLUGINS_DIR)
    if(WIN32)
        set(GITEASE_PLUGINS_DIR "$ENV{APPDATA}/GitEase/plugins")
    else()
        set(GITEASE_PLUGINS_DIR "$ENV{HOME}/.local/share/GitEase/plugins")
    endif()
endif()

if(GITEASE_PLUGINS_DIR)
    set(_PLUGIN_DEPLOY_DIR "${GITEASE_PLUGINS_DIR}/syntax-colors")
    message(STATUS "Auto-deploy -> ${_PLUGIN_DEPLOY_DIR}")

    add_custom_command(TARGET syntax-colors-plugin POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_PLUGIN_DEPLOY_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:syntax-colors-plugin>"
            "${_PLUGIN_DEPLOY_DIR}/lib/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/plugin.json"
            "${_PLUGIN_DEPLOY_DIR}/"
        COMMENT "Deploying syntax-colors -> ${_PLUGIN_DEPLOY_DIR}"
        VERBATIM
    )
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/../PackageGep.cmake")
gitease_package_gep(syntax-colors-plugin)
