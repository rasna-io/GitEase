cmake_minimum_required(VERSION 3.16)

project(GitEase VERSION 0.0.1 LANGUAGES CXX)

set(PROJECT_VERSION_SHORT ${CMAKE_PROJECT_VERSION_MAJOR}.${CMAKE_PROJECT_VERSION_MINOR}.${CMAKE_PROJECT_VERSION_PATCH})

set(CMAKE_AUTOMOC ON)
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_INCLUDE_CURRENT_DIR ON)


set(MAIN_TARGET_NAME ${CMAKE_PROJECT_NAME})
set(MAIN_TARGET_URI ${MAIN_TARGET_NAME})

set(THIRD_PARTY_DIR "${CMAKE_SOURCE_DIR}/Ext" CACHE PATH "Path to third-party libraries")

include(libgit.cmake)

# Flatten generation of all sub-dependent libraries
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Qml)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Gui Concurrent)

# Dependencies
add_subdirectory(Res/)
add_subdirectory(Qml/Style/)

# Extra QML File properties
set_source_files_properties(
    Qml/Core/Models/Enums.qml
    Qml/Core/Controllers/LayoutController.qml
    Qml/Core/Services/GitService.qml

    PROPERTIES
        QT_QML_SINGLETON_TYPE True
)


# Executable Definition
if (WIN32)
    qt_add_executable(${MAIN_TARGET_NAME}
        WIN32
        Src/main.cpp
    )

    # Embed .ico into the executable so Windows shortcuts use the app icon.
    set(WINDOWS_APP_ICON_RC "${CMAKE_SOURCE_DIR}/Res/Images/Logo.rc")
    set(WINDOWS_APP_ICON_ICO "${CMAKE_SOURCE_DIR}/Res/Images/Logo.ico")
    if (EXISTS "${WINDOWS_APP_ICON_RC}" AND EXISTS "${WINDOWS_APP_ICON_ICO}")
        target_sources(${MAIN_TARGET_NAME} PRIVATE "${WINDOWS_APP_ICON_RC}")
    endif()
else()
    qt_add_executable(${MAIN_TARGET_NAME}
        Src/main.cpp
    )
endif()


target_link_libraries(GitEase PRIVATE Qt6::Core)
target_include_directories(${MAIN_TARGET_NAME} PRIVATE ${INCLUDE_DIRS_BACKEND})

# NO_CACHEGEN is set for qt_add_qml_module() in DEBUG mode so we can have a better QML Preview
# functionality (Only Qt6.6 and later)
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(MODULE_CACHEGEN_STATE
        NO_CACHEGEN
    )
endif()



include(backend.cmake)
include(Resources.cmake)

# Project Files
qt_add_qml_module(${MAIN_TARGET_NAME}
    URI ${MAIN_TARGET_URI}
    VERSION 1.0
    ${MODULE_CACHEGEN_STATE}
    QML_FILES
        Qml/Main.qml
        ${RESOURCES_CORE}
        ${RESOURCES_UICORE}
        ${RESOURCES_COMPONENTS}
        ${RESOURCES_POPUPS}
        ${RESOURCES_PAGES}
        ${RESOURCES_VIEW}
        ${RESOURCES_SERVICES}

    SOURCES
        ${HEADERS_BACKEND}
        ${SOURCES_BACKEND}
)

target_link_libraries(${MAIN_TARGET_NAME} PRIVATE
    Qt6::Quick
    Qt6::Gui
    Qt6::Concurrent
    ${MAIN_TARGET_NAME}_Styleplugin
    ${MAIN_TARGET_NAME}_Style_Implplugin
    ${MAIN_TARGET_NAME}.Resourcesplugin
    libgit2
)


include(GNUInstallDirs)
install(TARGETS ${MAIN_TARGET_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)

if (WIN32)
    target_link_libraries(${MAIN_TARGET_NAME} PRIVATE dwmapi)
endif()

# Make Qt Creator aware of where the QML modules live
set(QML_IMPORT_PATH ${QT_QML_OUTPUT_DIRECTORY} CACHE STRING "QtCreator QML Modules Lookup")

include(CTest)
if (BUILD_TESTING)
    add_subdirectory(tests)
endif()

if(UNIX AND NOT APPLE)
    install(TARGETS ${MAIN_TARGET_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR})

    install(PROGRAMS gitease-launcher.sh DESTINATION ${CMAKE_INSTALL_BINDIR})

    install(FILES gitease.desktop DESTINATION share/applications)

    install(FILES Res/Images/Logo.png DESTINATION share/icons/hicolor/256x256/apps RENAME gitease.png)
endif()

include(packaging.cmake)
