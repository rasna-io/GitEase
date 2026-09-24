cmake_minimum_required(VERSION 3.16)
project(StatsPagePlugin VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick)

if(NOT DEFINED GITEASE_SDK_DIR OR GITEASE_SDK_DIR STREQUAL "")
    get_filename_component(GITEASE_SDK_DIR
        "${CMAKE_CURRENT_SOURCE_DIR}/../../Src/Plugins"
        ABSOLUTE)
endif()

if(NOT EXISTS "${GITEASE_SDK_DIR}/IPlugin.h")
    message(FATAL_ERROR "GitEase SDK not found at: ${GITEASE_SDK_DIR}")
endif()

add_library(stats-page-plugin SHARED
    StatsPagePlugin.h
    StatsPagePlugin.cpp
)

set_target_properties(stats-page-plugin PROPERTIES PREFIX "")

# Embed QML into the .dll as a Qt resource
qt_add_resources(stats-page-plugin "plugin_qml"
    PREFIX "/com.gitease.stats-page"
    FILES
        qml/StatsPage.qml
)

target_include_directories(stats-page-plugin PRIVATE ${GITEASE_SDK_DIR})

target_link_libraries(stats-page-plugin PRIVATE Qt6::Core Qt6::Quick)

# ── Auto-deploy ───────────────────────────────────────────────────────────────
if(NOT GITEASE_PLUGINS_DIR)
    file(GLOB _GITEASE_EXES
        "${CMAKE_CURRENT_SOURCE_DIR}/../../build/*/GitEase.exe"
        "${CMAKE_CURRENT_SOURCE_DIR}/../../build/*/*/GitEase.exe")
    if(_GITEASE_EXES)
        list(GET _GITEASE_EXES 0 _GITEASE_EXE)
        get_filename_component(_GITEASE_BINDIR "${_GITEASE_EXE}" DIRECTORY)
        set(GITEASE_PLUGINS_DIR "${_GITEASE_BINDIR}/plugins")
    endif()
endif()

if(GITEASE_PLUGINS_DIR)
    set(_DEPLOY_DIR "${GITEASE_PLUGINS_DIR}/stats-page")
    add_custom_command(TARGET stats-page-plugin POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory  "${_DEPLOY_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:stats-page-plugin>" "${_DEPLOY_DIR}/lib/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/plugin.json" "${_DEPLOY_DIR}/"
        COMMENT "Deploying stats-page-plugin → ${_DEPLOY_DIR}"
        VERBATIM
    )
endif()
