import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import GitEaseOrganizationRulesPlugin

/*! ***********************************************************************************************
 * NotificationRulesSettings
 * ************************************************************************************************/

RuleSettingsBase {
    id: root

    /* Property Declarations
     * ****************************************************************************************/


    /* Object Properties
     * ****************************************************************************************/
    contentHeight: contentColumn.implicitHeight

    onRuleDataChanged: loadFromModel()

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: contentColumn
        width: root.contentAvailableWidth
        spacing: 16

        BasicInfoRect {
            id: basicInfo
            ruleColor: root.ruleColor
            onRuleNameChanged: root.markDirty()
            onDescriptionChanged: root.markDirty()
            onSeverityIndexChanged: root.markDirty()
            onIsActiveChanged: root.markDirty()
        }

        RuleChip {
            headerText: "Channels"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 12

                OptionRow {
                    title: "Notify channel"
                    subtitle: "Slack, Teams or Discord webhook URL"

                    control: RuleTextField {
                        id: notifyChannelField
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        placeholderText: "https://hooks.slack.com/"

                        onTextChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Show in notification center"

                    control: ModernSwitch {
                        id: showInNotificationCenterSwitch
                        height: parent.height

                        onCheckedChanged: root.markDirty()
                    }
                }
            }
        }

        RuleChip {
            headerText: "Audit Log"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 12

                OptionRow {
                    title: "Log violations to file"

                    control: ModernSwitch {
                        id: logViolationsSwitch
                        height: parent.height

                        onCheckedChanged: root.markDirty()
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Log file path"

                    control: RuleTextField {
                        id: logFilePath
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        placeholderText: "/var/log/gitease/violations.log"
                        font.family: Style.fontTypes.jetBrainsMono

                        onTextChanged: root.markDirty()
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function loadFromModel() {
        suppressDirty = true
        if (!ruleData) { suppressDirty = false; return }

        basicInfo.ruleName = ruleData.ruleName ?? ""
        basicInfo.description = ruleData.description ?? ""
        basicInfo.severityIndex = ruleData.severity ?? 0
        basicInfo.isActive = ruleData.enabled ?? true

        notifyChannelField.text = ruleData.notifyChannel ?? ""
        showInNotificationCenterSwitch.checked = ruleData.showInNotificationCenter ?? false

        logViolationsSwitch.checked = ruleData.logViolationsToFile ?? false
        logFilePath.text = ruleData.logFilePath ?? ""

        isDirty = false
        suppressDirty = false
    }

    function saveChanges() {
        if (!targetModel || ruleIndex < 0) return

        targetModel.setProperty(ruleIndex, "ruleName", basicInfo.ruleName)
        targetModel.setProperty(ruleIndex, "description", basicInfo.description)
        targetModel.setProperty(ruleIndex, "severity", basicInfo.severityIndex)
        targetModel.setProperty(ruleIndex, "enabled", basicInfo.isActive)

        targetModel.setProperty(ruleIndex, "notifyChannel", notifyChannelField.text)
        targetModel.setProperty(ruleIndex, "showInNotificationCenter", showInNotificationCenterSwitch.checked)

        targetModel.setProperty(ruleIndex, "logViolationsToFile", logViolationsSwitch.checked)
        targetModel.setProperty(ruleIndex, "logFilePath", logFilePath.text)

        isDirty = false
    }
}
