cmake_minimum_required(VERSION 3.16)
project(RepoNotesPlugin VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick)

# ── Locate GitEase SDK headers ───────────────────────────────────────────────
# Auto-detects Src/Plugins/ relative to this file's location (two levels up).
# Override with -DGITEASE_SDK_DIR=<absolute path> if building outside the repo.
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

# ── Shared library target ────────────────────────────────────────────────────
add_library(repo-notes-plugin SHARED
    RepoNotesPlugin.h
    RepoNotesPlugin.cpp
)

# On Windows CMake adds "lib" prefix automatically for MinGW — strip it
# so the output matches plugin.json: "lib/repo-notes-plugin.dll"
set_target_properties(repo-notes-plugin PROPERTIES
    PREFIX ""
)

# Embed QML as a Qt resource inside the .dll — source is NOT on disk at runtime
qt_add_resources(repo-notes-plugin "plugin_qml"
    PREFIX "/com.gitease.repo-notes"
    FILES
        qml/NotesDock.qml
)

set(_GITEASE_SRC "${GITEASE_SDK_DIR}/..")

target_include_directories(repo-notes-plugin PRIVATE
    ${GITEASE_SDK_DIR}
    ${_GITEASE_SRC}
    ${_GITEASE_SRC}/Git/
    ${_GITEASE_SRC}/Git/Auth/
    ${_GITEASE_SRC}/Git/Models/
    ${_GITEASE_SRC}/Git/Utilities/
)

target_link_libraries(repo-notes-plugin PRIVATE
    Qt6::Core
    Qt6::Quick
)

# ── Auto-deploy: copy .dll + plugin.json after every build ───────────────────
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
    set(_PLUGIN_DEPLOY_DIR "${GITEASE_PLUGINS_DIR}/repo-notes")
    message(STATUS "Auto-deploy → ${_PLUGIN_DEPLOY_DIR}")

    add_custom_command(TARGET repo-notes-plugin POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory  "${_PLUGIN_DEPLOY_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:repo-notes-plugin>"
            "${_PLUGIN_DEPLOY_DIR}/lib/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/plugin.json"
            "${_PLUGIN_DEPLOY_DIR}/"
        COMMENT "Deploying repo-notes → ${_PLUGIN_DEPLOY_DIR}"
        VERBATIM
    )
else()
    message(WARNING "GitEase.exe not found — plugin won't auto-deploy.")
endif()
