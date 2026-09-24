cmake_minimum_required(VERSION 3.16)
project(RepoForestPlugin VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Concurrent Core Quick)

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

add_library(repo-forest-plugin SHARED
    GitScanner.h
    GitScanner.cpp
    RepoForestPlugin.h
    RepoForestPlugin.cpp
)

set_target_properties(repo-forest-plugin PROPERTIES
    PREFIX ""
)

qt_add_resources(repo-forest-plugin "repo_forest_qml"
    PREFIX "/com.gitease.repo-forest"
    FILES
        qml/RepoForestDock.qml
        qml/RepoForest.qml
        qml/RepoForestLogs.qml
        qml/RepoItem.qml
)

set(_GITEASE_SRC "${GITEASE_SDK_DIR}/..")

target_include_directories(repo-forest-plugin PRIVATE
    ${GITEASE_SDK_DIR}
    ${_GITEASE_SRC}
    ${_GITEASE_SRC}/Git/
    ${_GITEASE_SRC}/Git/Auth/
    ${_GITEASE_SRC}/Git/Models/
    ${_GITEASE_SRC}/Git/Utilities/
)

target_link_libraries(repo-forest-plugin PRIVATE
    Qt6::Concurrent
    Qt6::Core
    Qt6::Quick
)

set(_SOURCE_PLUGIN_DIR "${CMAKE_CURRENT_SOURCE_DIR}")

add_custom_command(TARGET repo-forest-plugin POST_BUILD
    COMMAND ${CMAKE_COMMAND} -E make_directory "${_SOURCE_PLUGIN_DIR}/lib"
    COMMAND ${CMAKE_COMMAND} -E copy_if_different
        "$<TARGET_FILE:repo-forest-plugin>"
        "${_SOURCE_PLUGIN_DIR}/lib/"
    COMMENT "Copying repo-forest DLL into SamplePlugins/repo-forest/lib"
    VERBATIM
)

if(NOT GITEASE_PLUGINS_DIR)
    if(WIN32)
        set(GITEASE_PLUGINS_DIR "$ENV{APPDATA}/GitEase/plugins")
    else()
        set(GITEASE_PLUGINS_DIR "$ENV{HOME}/.local/share/GitEase/plugins")
    endif()
endif()

if(GITEASE_PLUGINS_DIR)
    set(_PLUGIN_DEPLOY_DIR "${GITEASE_PLUGINS_DIR}/repo-forest")
    message(STATUS "Auto-deploy -> ${_PLUGIN_DEPLOY_DIR}")

    add_custom_command(TARGET repo-forest-plugin POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_PLUGIN_DEPLOY_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:repo-forest-plugin>"
            "${_PLUGIN_DEPLOY_DIR}/lib/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/plugin.json"
            "${_PLUGIN_DEPLOY_DIR}/"
        COMMENT "Deploying repo-forest -> ${_PLUGIN_DEPLOY_DIR}"
        VERBATIM
    )
endif()
