cmake_minimum_required(VERSION 3.16)

if(NOT DEFINED MAIN_TARGET_NAME)
    message(FATAL_ERROR "MAIN_TARGET_NAME must be defined before including Style.cmake. Define it in your main CMakeLists.txt.")
endif()

project(${MAIN_TARGET_NAME}_Style VERSION 0.1 LANGUAGES CXX)
set(STYLE_TARGET_URI ${MAIN_TARGET_URI}_Style)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick QuickControls2 Core5Compat)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set_source_files_properties(
    Style.qml

    PROPERTIES
        QT_QML_SINGLETON_TYPE True
)

# NO_CACHEGEN is set for qt_add_qml_module() in DEBUG mode so we can have a better QML Preview
# functionality (Only Qt6.6 and later)
if (CMAKE_BUILD_TYPE STREQUAL "Debug")
    set(MODULE_CACHEGEN_STATE
        NO_CACHEGEN
    )
endif()

qt_add_qml_module(${MAIN_TARGET_NAME}_Style
    URI ${STYLE_TARGET_URI}
    STATIC
    ${MODULE_CACHEGEN_STATE}
    VERSION 1.0
    IMPORTS QtQuick.Controls.Material
    QML_FILES
        FontTypes.qml
        Style.qml
        AppFontSize.qml
        Colors.qml
        FontIconSize.qml
        Icons.qml
)


qt_add_qml_module(${MAIN_TARGET_NAME}_Style_Impl
    URI ${MAIN_TARGET_NAME}_Style_Impl
    STATIC
    VERSION 1.0
    IMPORTS QtQuick.Controls.Material.impl
    ${MODULE_CACHEGEN_STATE}

    QML_FILES
        impl/RoniaTextIcon.qml
        impl/Button.qml
        impl/ComboBox.qml
        impl/TabButton.qml
        impl/TabBar.qml
        impl/ToolButton.qml
        impl/Popup.qml
        impl/ScrollBar.qml
        impl/TextField.qml
        impl/Dialog.qml
        impl/RoundButton.qml
        impl/Pane.qml
        impl/Frame.qml
        impl/SpinBox.qml
        impl/Switch.qml
)

target_link_libraries(${MAIN_TARGET_NAME}_Style PRIVATE
    Qt6::Quick
    Qt6::QuickControls2
)
