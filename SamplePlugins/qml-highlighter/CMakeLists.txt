cmake_minimum_required(VERSION 3.16)
project(QmlHighlighterPlugin VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Widgets)

# ── Locate GitEase SDK (auto-detect when inside the repo) ────────────────────
if(NOT DEFINED GITEASE_SDK_DIR OR GITEASE_SDK_DIR STREQUAL "")
    get_filename_component(GITEASE_SDK_DIR
        "${CMAKE_CURRENT_SOURCE_DIR}/../../Src/Plugins"
        ABSOLUTE)
endif()

if(NOT EXISTS "${GITEASE_SDK_DIR}/IPlugin.h")
    message(FATAL_ERROR
        "GitEase SDK not found at: ${GITEASE_SDK_DIR}\n"
        "Pass -DGITEASE_SDK_DIR=<path/to/GitEase/Src/Plugins> to CMake.")
endif()

message(STATUS "GitEase SDK: ${GITEASE_SDK_DIR}")

# ── Target ───────────────────────────────────────────────────────────────────
add_library(qml-highlighter-plugin SHARED
    QmlHighlighterPlugin.h
    QmlHighlighterPlugin.cpp
    QmlSyntaxHighlighter.h
    QmlSyntaxHighlighter.cpp
)

set_target_properties(qml-highlighter-plugin PROPERTIES PREFIX "")

# Embed the dock QML inside the .dll — source not visible on disk at runtime
qt_add_resources(qml-highlighter-plugin "plugin_qml"
    PREFIX "/gitease.qml-highlighter"
    FILES
        qml/HighlighterDock.qml
)

set(_GITEASE_SRC "${GITEASE_SDK_DIR}/..")

target_include_directories(qml-highlighter-plugin PRIVATE
    ${GITEASE_SDK_DIR}
    ${_GITEASE_SRC}
    ${_GITEASE_SRC}/Git/
    ${_GITEASE_SRC}/Git/Auth/
    ${_GITEASE_SRC}/Git/Models/
)

target_link_libraries(qml-highlighter-plugin PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Widgets    # QSyntaxHighlighter lives in QtWidgets
)

# ── Auto-deploy: copy .dll + plugin.json after every build ───────────────────
# Searches sibling build dirs for GitEase.exe; override with -DGITEASE_PLUGINS_DIR=...
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
    set(_PLUGIN_DEPLOY_DIR "${GITEASE_PLUGINS_DIR}/qml-highlighter")
    message(STATUS "Auto-deploy → ${_PLUGIN_DEPLOY_DIR}")

    add_custom_command(TARGET qml-highlighter-plugin POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory  "${_PLUGIN_DEPLOY_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:qml-highlighter-plugin>"
            "${_PLUGIN_DEPLOY_DIR}/lib/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/plugin.json"
            "${_PLUGIN_DEPLOY_DIR}/"
        COMMENT "Deploying qml-highlighter → ${_PLUGIN_DEPLOY_DIR}"
        VERBATIM
    )
else()
    message(WARNING
        "GitEase.exe not found — plugin won't auto-deploy.\n"
        "Pass -DGITEASE_PLUGINS_DIR=<path/to/build/plugins> to CMake.")
endif()
