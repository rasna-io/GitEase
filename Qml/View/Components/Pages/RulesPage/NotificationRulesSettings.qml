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

    /* Object Properties
     * ****************************************************************************************/
    contentWidth: width
    contentHeight: contentColumn.implicitHeight
    clip: true

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: contentColumn
        width: root.width
        spacing: 5

        BasicInfoRect {
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
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Log file path"

                    control: TextField {
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
}
