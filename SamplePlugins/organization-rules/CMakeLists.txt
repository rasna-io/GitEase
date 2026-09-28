cmake_minimum_required(VERSION 3.16)

project(OrganizationRulesPlugin VERSION 1.0.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_AUTOMOC ON)

find_package(Qt6 REQUIRED COMPONENTS Core Quick Network)

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

set(_GITEASE_SRC "${GITEASE_SDK_DIR}/..")


add_library(organization-rules-plugin SHARED
    OrganizationRulesPlugin.h
    OrganizationRulesPlugin.cpp
    RuleManager.h
    RuleManager.cpp
    CommitMessageValidator.h
    CommitMessageValidator.cpp
    BranchNameValidator.h
    BranchNameValidator.cpp
    FileRuleValidator.h
    FileRuleValidator.cpp
    PushRuleValidator.h
    PushRuleValidator.cpp
    HookRunner.h
    HookRunner.cpp
    ViolationReporter.h
    ViolationReporter.cpp
    RuleSupport.h
    RuleSupport.cpp
)

set_target_properties(organization-rules-plugin PROPERTIES PREFIX "")

# GitResult is a Q_GADGET; moc it in the plugin without QML_ELEMENT (host registers it).
target_compile_definitions(organization-rules-plugin PRIVATE GITEASE_SKIP_QML_ELEMENT)
target_sources(organization-rules-plugin PRIVATE ${_GITEASE_SRC}/Git/GitResult.h)

qt_add_resources(organization-rules-plugin "organization_rules_qml"
    PREFIX "/com.gitease.organization-rules"
    FILES
        qml/RulesDock.qml
        qml/RulesPage.qml
        qml/DividerLine.qml
        qml/RuleChip.qml
        qml/OptionRow.qml
        qml/BasicInfoRect.qml
        qml/ModernSwitch.qml
        qml/RuleButton.qml
        qml/RuleScrollBar.qml
        qml/RuleTextField.qml
        qml/SegmentedSelector.qml
        qml/RuleSettingsBase.qml
        qml/CommitMessageSettings.qml
        qml/BranchNamingSettings.qml
        qml/FileSettings.qml
        qml/PushRulesSettings.qml
        qml/NotificationRulesSettings.qml
        qml/CustomHooksSettings.qml
        qml/RulesTreeView.qml
        qml/RuleSettingsPanel.qml
        qml/AddRulePopup.qml
        qml/RuleImportPopup.qml
)



target_include_directories(organization-rules-plugin PRIVATE
    ${GITEASE_SDK_DIR}
    ${_GITEASE_SRC}
    ${_GITEASE_SRC}/Git/
    ${_GITEASE_SRC}/Git/Auth/
    ${_GITEASE_SRC}/Git/Models/
)

target_link_libraries(organization-rules-plugin PRIVATE
    Qt6::Core
    Qt6::Quick
    Qt6::Network
)

include("${CMAKE_CURRENT_SOURCE_DIR}/../PackageGep.cmake")
gitease_package_gep(organization-rules-plugin)

if(NOT GITEASE_PLUGINS_DIR)
    if(WIN32)
        set(GITEASE_PLUGINS_DIR "$ENV{APPDATA}/GitEase/plugins")
    else()
        set(GITEASE_PLUGINS_DIR "$ENV{HOME}/.local/share/GitEase/plugins")
    endif()
endif()

if(GITEASE_PLUGINS_DIR)
    set(_PLUGIN_DEPLOY_DIR "${GITEASE_PLUGINS_DIR}/organization-rules")
    message(STATUS "Auto-deploy -> ${_PLUGIN_DEPLOY_DIR}")

    add_custom_command(TARGET organization-rules-plugin POST_BUILD
        COMMAND ${CMAKE_COMMAND} -E make_directory "${_PLUGIN_DEPLOY_DIR}/lib"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "$<TARGET_FILE:organization-rules-plugin>"
            "${_PLUGIN_DEPLOY_DIR}/lib/"
        COMMAND ${CMAKE_COMMAND} -E copy_if_different
            "${CMAKE_CURRENT_SOURCE_DIR}/plugin.json"
            "${_PLUGIN_DEPLOY_DIR}/"
        COMMENT "Deploying organization-rules -> ${_PLUGIN_DEPLOY_DIR}"
        VERBATIM
    )
endif()