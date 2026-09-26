cmake_minimum_required(VERSION 3.16)
project(QmlDiffPlugin VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick)

# ── Locate GitEase SDK ────────────────────────────────────────────────────────
if(NOT DEFINED GITEASE_SDK_DIR OR GITEASE_SDK_DIR STREQUAL "")
    get_filename_component(GITEASE_SDK_DIR
        "${CMAKE_CURRENT_SOURCE_DIR}/../../Src/Plugins"
        ABSOLUTE)
endif()

if(NOT EXISTS "${GITEASE_SDK_DIR}/IPlugin.h")
    message(FATAL_ERROR
        "GitEase SDK not found at: ${GITEASE_SDK_DIR}\n"
        "Pass -DGITEASE_SDK_DIR=<absolute/path/to/GitEase/Src/Plugins> to CMake.")
endif()

message(STATUS "GitEase SDK: ${GITEASE_SDK_DIR}")

# ── Target ───────────────────────────────────────────────────────────────────
add_library(qml-diff-plugin SHARED
    QmlDiffPlugin.h
    QmlDiffPlugin.cpp
)

set_target_properties(qml-diff-plugin PROPERTIES PREFIX "")

qt_add_resources(qml-diff-plugin "plugin_qml"
    PREFIX "/gitease.qml-diff"
    FILES
        qml/QmlColorizer.qml
)

target_include_directories(qml-diff-plugin PRIVATE
    ${GITEASE_SDK_DIR}
)

target_link_libraries(qml-diff-plugin PRIVATE
    Qt6::Core
    Qt6::Quick
)

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
    set(_PLUGIN_DEPLOY_DIR "${GITEASE_PLUGINS_DIR}/qml-diff")
    message(STATUS "Auto-deploy → ${_PLUGIN_DEPLOY_DIR}")

    add_custom_command(TARGET qml-diff-plugin POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory  "${_PLUGIN_DEPLOY_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:qml-diff-plugin>"
            "${_PLUGIN_DEPLOY_DIR}/lib/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/plugin.json"
            "${_PLUGIN_DEPLOY_DIR}/"
        COMMENT "Deploying qml-diff → ${_PLUGIN_DEPLOY_DIR}"
        VERBATIM
    )
else()
    message(WARNING "GitEase.exe not found — plugin won't auto-deploy.")
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/../PackageGep.cmake")
gitease_package_gep(qml-diff-plugin)
