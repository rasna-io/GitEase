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

# ========== EMBEDDED LIBGIT2 SETUP ==========
# Paths relative to PROJECT_SOURCE_DIR
set(LIBGIT2_ROOT "${THIRD_PARTY_DIR}/libgit2_mingw")
set(LIBGIT2_INCLUDE_DIR "${LIBGIT2_ROOT}/include")
set(LIBGIT2_LIBRARY "${LIBGIT2_ROOT}/lib/libgit2.a")

# Verify the files exist
if(NOT EXISTS "${LIBGIT2_INCLUDE_DIR}/git2.h")
    message(FATAL_ERROR "git2.h not found at ${LIBGIT2_INCLUDE_DIR}. Please copy libgit2 files to Ext/libgit2_mingw/")
endif()

if(NOT EXISTS "${LIBGIT2_LIBRARY}")
    message(FATAL_ERROR "libgit2.a not found at ${LIBGIT2_LIBRARY}. Please copy libgit2.a to Ext/libgit2_mingw/lib/")
endif()

message(STATUS "Using embedded libgit2 from: ${LIBGIT2_ROOT}")
message(STATUS "Libgit2 include dir: ${LIBGIT2_INCLUDE_DIR}")
# ========== END LIBGIT2 SETUP ==========


# Flatten generation of all sub-dependent libraries
set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/Qml)

find_package(Qt6 REQUIRED COMPONENTS Quick Gui)

# Dependencies
add_subdirectory(Res/)
add_subdirectory(Qml/Style/)

# Extra QML File properties
set_source_files_properties(

    PROPERTIES
        QT_QML_SINGLETON_TYPE True
)


# Executable Definition
qt_add_executable(${MAIN_TARGET_NAME}
    Src/main.cpp
)

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

    SOURCES
        ${HEADERS_BACKEND}
        ${SOURCES_BACKEND}

)

target_link_libraries(${MAIN_TARGET_NAME} PRIVATE
    Qt6::Quick
    Qt6::Gui
    ${MAIN_TARGET_NAME}_Styleplugin
    ${MAIN_TARGET_NAME}_Style_Implplugin
    ${MAIN_TARGET_NAME}.Resourcesplugin
)


include(GNUInstallDirs)
install(TARGETS ${MAIN_TARGET_NAME}
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)


# Make Qt Creator aware of where the QML modules live
set(QML_IMPORT_PATH ${QT_QML_OUTPUT_DIRECTORY} CACHE STRING "QtCreator QML Modules Lookup")
