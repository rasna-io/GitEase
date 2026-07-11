import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*!
 * BasicInfoRect
 * Showing basic info for each rule (name, description, severity, enabled)
 * Used for every rule
 */

RuleChip {
    headerText: "Basic"
    Layout.fillWidth: true
    ruleColor: root.ruleColor

    content: ColumnLayout {
        spacing: 7

        OptionRow {
            title: "Rule Name"

            control: TextField {
                anchors.fill: parent
                placeholderText: "Type a name for the rule..."
                selectByMouse: true

                background: Rectangle {
                    color: Style.colors.secondaryBackground
                    radius: 5
                }
            }
        }

        DividerLine {}

        OptionRow {
            title: "Description"
            rowHeight: 80

            control: ModernInputArea {
                anchors.fill: parent
                placeholder: "Write some descriptions about your commmitiing style"
                color: Style.colors.secondaryBackground
                border.width: 0
                fontSize: 11
            }
        }

        DividerLine {}

        OptionRow {
            title: "Severity"

            control: RowLayout {
                anchors.fill: parent

                Row {
                    id: severitySelector
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 0

                    property int severityCurrentIndex: 0

                    Repeater {
                        model: [
                            { text: "Error", color: "#E53935" },
                            { text: "Warning", color: "#FB8C00" },
                            { text: "Info", color: "#152741" }
                        ]

                        delegate: Rectangle {
                            width: 60
                            height: 30

                            color: severitySelector.severityCurrentIndex === index
                                   ? modelData.color
                                   : "transparent"

                            border.width: 1
                            border.color: severitySelector.severityCurrentIndex === index
                                          ? modelData.color
                                          : Style.colors.secondaryText

                            Text {
                                anchors.centerIn: parent
                                text: modelData.text
                                color: severitySelector.severityCurrentIndex === index
                                       ? "white"
                                       : "#DDD"
                                font.bold: severitySelector.severityCurrentIndex === index
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: 11
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: severitySelector.severityCurrentIndex = index
                            }
                        }
                    }
                }
            }

        }

        DividerLine {}

        OptionRow {
            title: "Enabled"

            control: Item {
                width: 50
                height: parent.height
                Layout.margins: 0

                Switch {
                    anchors.fill: parent
                    Material.accent: Style.colors.accent
                    scale: 0.8
                }
            }
        }
    }
}


