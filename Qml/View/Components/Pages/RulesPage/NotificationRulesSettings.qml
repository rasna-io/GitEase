import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * NotificationRulesSettings
 * ************************************************************************************************/

Flickable {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string ruleColor: ""
    property var ruleData
    property var targetModel
    property int ruleIndex: -1

    /* Object Properties
     * ****************************************************************************************/
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    clip: true

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    onRuleDataChanged: loadFromModel()

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: 5

        BasicInfoRect {
            id: basicInfo
            ruleColor: root.ruleColor
        }

        RuleChip {
            headerText: "Channels"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Notify channel"
                    subtitle: "Slack webhook or email"

                    control: TextField {
                        id: notifyChannelField
                        anchors.fill: parent
                        placeholderText: "https://hooks.slack.com/"
                        selectByMouse: true

                        background: Rectangle {
                            implicitHeight: 40
                            color: Style.colors.secondaryBackground
                            radius: 5
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Show in notification center"

                    control: ModernSwitch {
                        id: showInNotificationCenterSwitch
                        height: parent.height
                    }
                }
            }
        }

        RuleChip {
            headerText: "Audit Log"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Log violations to file"

                    control: ModernSwitch {
                        id: logViolationsSwitch
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Log file path"

                    control: TextField {
                        id: logFilePath
                        anchors.fill: parent
                        placeholderText: "/var/log/gitease/violations.log"
                        selectByMouse: true

                        background: Rectangle {
                            implicitHeight: 40
                            color: Style.colors.secondaryBackground
                            radius: 5
                        }
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function loadFromModel() {
        if (!ruleData) return

        basicInfo.ruleName = ruleData.ruleName ?? ""
        basicInfo.description = ruleData.description ?? ""
        basicInfo.severityIndex = ruleData.severity ?? 0
        basicInfo.isActive = ruleData.enabled ?? true

        notifyChannelField.text = ruleData.notifyChannel ?? ""
        showInNotificationCenterSwitch.checked = ruleData.showInNotificationCenter ?? false

        logViolationsSwitch.checked = ruleData.logViolationsToFile ?? false
        logFilePath.text = ruleData.logFilePath ?? ""
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
    }
}
