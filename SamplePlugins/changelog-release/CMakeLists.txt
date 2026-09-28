cmake_minimum_required(VERSION 3.16)
project(ChangelogReleasePlugin VERSION 1.0.0 LANGUAGES CXX)

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

add_library(changelog-release-plugin SHARED
    ChangelogReleasePlugin.h
    ChangelogReleasePlugin.cpp
    ReleaseEngine.h
    ReleaseEngine.cpp
)

set_target_properties(changelog-release-plugin PROPERTIES
    PREFIX ""
)

qt_add_resources(changelog-release-plugin "changelog_release_qml"
    PREFIX "/com.gitease.changelog-release"
    FILES
        qml/ChangelogPage.qml
        qml/ReleaseView.qml
        qml/ReleaseCommitRow.qml
        qml/ReleaseDetailsView.qml
        qml/ReleaseButton.qml
        qml/NotesPreview.qml
        qml/ReleaseHistoryView.qml
        qml/ReleaseCard.qml
        qml/ReleaseLabel.qml
        qml/ReleaseBadge.qml
        qml/ReleaseEmptyState.qml
)

target_include_directories(changelog-release-plugin PRIVATE
    ${GITEASE_SDK_DIR}
)

target_link_libraries(changelog-release-plugin PRIVATE
    Qt6::Concurrent
    Qt6::Core
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
    set(_PLUGIN_DEPLOY_DIR "${GITEASE_PLUGINS_DIR}/changelog-release")
    message(STATUS "Auto-deploy -> ${_PLUGIN_DEPLOY_DIR}")

    add_custom_command(TARGET changelog-release-plugin POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_PLUGIN_DEPLOY_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:changelog-release-plugin>"
            "${_PLUGIN_DEPLOY_DIR}/lib/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/plugin.json"
            "${_PLUGIN_DEPLOY_DIR}/"
        COMMENT "Deploying changelog-release -> ${_PLUGIN_DEPLOY_DIR}"
        VERBATIM
    )
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/../PackageGep.cmake")
gitease_package_gep(changelog-release-plugin)
