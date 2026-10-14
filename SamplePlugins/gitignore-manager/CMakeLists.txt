cmake_minimum_required(VERSION 3.16)
project(GitignoreManagerPlugin VERSION 1.0.0 LANGUAGES CXX)

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

add_library(gitignore-manager-plugin SHARED
    GitignoreManagerPlugin.h
    GitignoreManagerPlugin.cpp
    GitignoreEngine.h
    GitignoreEngine.cpp
    IgnoreFile.h
    IgnoreFile.cpp
    IgnorePatterns.h
    IgnorePatterns.cpp
    OperationResult.h
    OperationResult.cpp
    RepositoryScanner.h
    RepositoryScanner.cpp
    RuleEditor.h
    RuleEditor.cpp
    TemplateStore.h
    TemplateStore.cpp
)

set_target_properties(gitignore-manager-plugin PROPERTIES
    PREFIX ""
)

qt_add_resources(gitignore-manager-plugin "gitignore_manager_qml"
    PREFIX "/com.gitease.gitignore-manager"
    FILES
        qml/FileFilterBar.qml
        qml/FileFilterChip.qml
        qml/FileSelectionBar.qml
        qml/FileTreeRow.qml
        qml/FilesView.qml
        qml/GitignoreBadge.qml
        qml/GitignoreButton.qml
        qml/GitignoreCard.qml
        qml/GitignoreCheckBox.qml
        qml/GitignoreCodeEditor.qml
        qml/GitignoreDialog.qml
        qml/GitignoreEmptyState.qml
        qml/GitignoreFileToolbar.qml
        qml/GitignoreHeader.qml
        qml/GitignoreHeaderTabs.qml
        qml/GitignoreIconAction.qml
        qml/GitignoreLabel.qml
        qml/GitignoreLineRow.qml
        qml/GitignorePage.qml
        qml/GitignoreSearchField.qml
        qml/GitignoreStatusBadge.qml
        qml/GitignoreTextLink.qml
        qml/GitignoreToolTip.qml
        qml/GitignoreView.qml
        qml/PatternInput.qml
        qml/PatternModeTab.qml
        qml/TemplateCategoryRow.qml
        qml/TemplateEditorDialog.qml
        qml/TemplatePreview.qml
        qml/TemplateRow.qml
        qml/TemplatesView.qml
        qml/TreeContextMenu.qml
        qml/UnignoreDialog.qml
        qml/UnignoreRuleRow.qml
        qml/FileTree.js
        templates/index.json
        templates/AITools.gitignore
        templates/SecretsAndKeys.gitignore
        templates/CloudCredentials.gitignore
        templates/Android.gitignore
        templates/C.gitignore
        templates/CMake.gitignore
        templates/CPlusPlus.gitignore
        templates/Dart.gitignore
        templates/Dotnet.gitignore
        templates/Go.gitignore
        templates/Gradle.gitignore
        templates/Java.gitignore
        templates/JetBrains.gitignore
        templates/Linux.gitignore
        templates/macOS.gitignore
        templates/Maven.gitignore
        templates/Node.gitignore
        templates/PHP.gitignore
        templates/Python.gitignore
        templates/Qt.gitignore
        templates/Ruby.gitignore
        templates/Rust.gitignore
        templates/Swift.gitignore
        templates/Terraform.gitignore
        templates/Unity.gitignore
        templates/VisualStudio.gitignore
        templates/VisualStudioCode.gitignore
        templates/Windows.gitignore
)

target_include_directories(gitignore-manager-plugin PRIVATE
    ${GITEASE_SDK_DIR}
)

target_link_libraries(gitignore-manager-plugin PRIVATE
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
    set(_PLUGIN_DEPLOY_DIR "${GITEASE_PLUGINS_DIR}/gitignore-manager")
    message(STATUS "Auto-deploy -> ${_PLUGIN_DEPLOY_DIR}")

    add_custom_command(TARGET gitignore-manager-plugin POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_PLUGIN_DEPLOY_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:gitignore-manager-plugin>"
            "${_PLUGIN_DEPLOY_DIR}/lib/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/plugin.json"
            "${_PLUGIN_DEPLOY_DIR}/"
        COMMENT "Deploying gitignore-manager -> ${_PLUGIN_DEPLOY_DIR}"
        VERBATIM
    )
endif()

include("${CMAKE_CURRENT_SOURCE_DIR}/../PackageGep.cmake")
gitease_package_gep(gitignore-manager-plugin)
