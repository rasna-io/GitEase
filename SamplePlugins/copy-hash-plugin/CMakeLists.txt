cmake_minimum_required(VERSION 3.16)
project(CopyHashPlugin VERSION 1.0.0 LANGUAGES CXX)

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
    message(FATAL_ERROR "GitEase SDK not found at: ${GITEASE_SDK_DIR}")
endif()

add_library(copy-hash-plugin SHARED
    CopyHashPlugin.h
    CopyHashPlugin.cpp
)

set_target_properties(copy-hash-plugin PROPERTIES PREFIX "")

target_include_directories(copy-hash-plugin PRIVATE ${GITEASE_SDK_DIR})

target_link_libraries(copy-hash-plugin PRIVATE Qt6::Core Qt6::Gui Qt6::Quick)

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
    set(_DEPLOY_DIR "${GITEASE_PLUGINS_DIR}/copy-hash")
    add_custom_command(TARGET copy-hash-plugin POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory  "${_DEPLOY_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "$<TARGET_FILE:copy-hash-plugin>" "${_DEPLOY_DIR}/lib/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different "${CMAKE_CURRENT_SOURCE_DIR}/plugin.json" "${_DEPLOY_DIR}/"
        COMMENT "Deploying copy-hash-plugin → ${_DEPLOY_DIR}"
        VERBATIM
    )
endif()
