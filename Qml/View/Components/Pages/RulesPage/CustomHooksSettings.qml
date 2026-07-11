import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * CustomHooksSettings
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
            headerText: "Trigger"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Hook trigger"

                    control: ComboBox {
                        id: triggerCombo
                        width: 200
                        minHeight: 40
                        focusBorderWidth: 1
                        font.family: Style.fontTypes.roboto
                        font.weight: 400
                        font.pixelSize: 12
                        model: ListModel {
                                 id: model
                                 ListElement { text: "pre-commit" }
                                 ListElement { text: "commit-msg" }
                                 ListElement { text: "pre-push" }
                                 ListElement { text: "post-merge" }
                                 ListElement { text: "post-checkout" }
                        }
                        currentIndex: 0

                        Material.background: Style.colors.primaryBackground
                        Material.foreground: Style.colors.secondaryText

                        background: Rectangle {
                            radius: 5
                            color: triggerCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                            border.color: triggerCombo.activeFocus ? Style.colors.accent : "transparent"
                        }
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Run in background"
                    subtitle: "Async, non-blocking"

                    control: ModernSwitch {
                        height: parent.height
                    }
                }

                DividerLine {}

                OptionRow {
                    title: "Timeout"
                    subtitle: "Seconds"

                    control: ModernSpinBox {
                    }
                }
            }
        }

        RuleChip {
            headerText: "Script"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Script path"
                    subtitle: "Relative to repo root"

                    control: TextField {
                        anchors.fill: parent
                        placeholderText: "./scripts/lint.sh"
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
                    title: "Inline script"
                    subtitle: "Overrides path if set"
                    rowHeight: inputArea.height

                    control: ModernInputArea {
                        id: inputArea

                        width: parent.width
                        height: 100

                        color: Style.colors.secondaryBackground
                        border.width: 0
                        fontSize: 11
                    }
                }
            }
        }

        RuleChip {
            headerText: "Environment & Failure"
            Layout.fillWidth: true
            ruleColor: root.ruleColor

            content: ColumnLayout {
                spacing: 7

                OptionRow {
                    title: "Environment vars"

                    rowHeight: variablesRect.height

                    ListModel {
                        id: listModel
                    }

                    control: Rectangle {
                        id: variablesRect
                        width: parent.width
                        color: "transparent"
                        implicitHeight: variablesColumn.implicitHeight

                        ColumnLayout {
                            id: variablesColumn

                            anchors.fill: parent
                            spacing: 0

                            ListView {
                                id: listView

                                Layout.fillWidth: true
                                Layout.preferredHeight: contentHeight

                                model: listModel
                                spacing: 5
                                clip: true

                                visible: count !== 0

                                delegate: RowLayout {
                                    width: listView.width
                                    height: 30

                                    TextField {
                                        id: textField

                                        text: key

                                        Layout.preferredWidth: 80
                                        Layout.preferredHeight: 30

                                        placeholderText: "KEY"
                                        selectByMouse: true

                                        background: Rectangle {
                                            color: Style.colors.secondaryBackground
                                            radius: 5
                                        }
                                    }

                                    Text {
                                        text: "="
                                        verticalAlignment: Text.AlignVCenter
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 12
                                        color: Style.colors.placeholderText
                                    }

                                    TextField {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 30

                                        text: value

                                        placeholderText: "value"
                                        selectByMouse: true

                                        background: Rectangle {
                                            color: Style.colors.secondaryBackground
                                            radius: 5
                                        }
                                    }

                                    ToolButton {
                                        Layout.alignment: Qt.AlignVCenter
                                        Layout.preferredWidth: 20
                                        Layout.preferredHeight: 20

                                        padding: 0

                                        contentItem: Text {
                                            text: "×"
                                            color: Style.colors.placeholderText
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        onClicked: listModel.remove(index)
                                    }
                                }
                            }

                            Button {
                                Layout.preferredWidth: 120
                                Layout.alignment: Qt.AlignVCenter
                                implicitHeight: 40

                                background: Rectangle {
                                    radius: 5
                                    color: Style.colors.accent
                                }

                                contentItem: Item {
                                    anchors.fill: parent

                                    Row {
                                        spacing: 10
                                        anchors.centerIn: parent

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: Style.icons.plus
                                            font.family: Style.fontTypes.font6Pro
                                            font.pixelSize: 12
                                            color: Style.colors.textButton
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Add variable"
                                            color: Style.colors.textButton
                                            font.pixelSize: 13
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }

                                onClicked: {
                                    listModel.append({
                                        key: "",
                                        value: ""
                                    })
                                }
                            }

                        }

                    }
                }

                DividerLine {}

                OptionRow {
                    title: "On failure"

                    control: Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0

                        Repeater {
                            model: [
                                { text: "Block", color: "#E53935" },
                                { text: "Warn", color: "#FB8C00" },
                                { text: "Ignore", color: "#152741" }
                            ]

                            delegate: Rectangle {
                                width: 60
                                height: 30

                                color: root.severityCurrentIndex === index
                                       ? modelData.color
                                       : "transparent"

                                border.width: 1
                                border.color: root.severityCurrentIndex === index
                                              ? modelData.color
                                              : "#555"

                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.text
                                    color: root.severityCurrentIndex === index
                                           ? "white"
                                           : "#DDD"
                                    font.bold: root.severityCurrentIndex === index
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 11
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.severityCurrentIndex = index
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
