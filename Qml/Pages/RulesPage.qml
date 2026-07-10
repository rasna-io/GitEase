import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/


    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent


    /* Children
     * ****************************************************************************************/
    ListModel {
        id: rulesModel

        ListElement {
            name: "COMMIT MESSAGE"
            enable: "true"
            description: "Enforce message format, prefixes & length"
            ruleColor: "#58a6ff"
        }

        ListElement {
            name: "BRANCH NAMING"
            enable: "true"
            description: "Naming patterns, forbidden chars & protection"
            ruleColor: "#3fb950"
        }

        ListElement {
            name: "FILE & CODE"
            enable: "true"
            description: "Extensions, secrets & file size limits"
            ruleColor: "#f0883e"
        }

        ListElement {
            name: "PUSH RULES"
            enable: "true"
            description: "Force-push, deletion & GPG requirements"
            ruleColor: "#f85149"
        }

        ListElement {
            name: "CUSTOM HOOKS"
            enable: "true"
            description: "Custom pre-commit/push scripts"
            ruleColor: "#d2a8ff"
        }
    }

    AddRulePopup {
        id: addRulePopup

        rulesModel: rulesModel
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Left column - Showing different rules type
        Rectangle {
            Layout.preferredWidth: 300
            Layout.fillHeight: true
            color: "transparent"
            border.width: 1
            border.color: Style.colors.secondaryBackground
            radius: 5

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 15

                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "Rules"
                        Layout.fillWidth: true
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 13
                        color: Style.colors.placeholderText
                    }

                    Button {
                        Layout.preferredWidth: 90
                        implicitHeight: 44

                        background: Rectangle {
                            radius: 8
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
                                    font.bold: true
                                }

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Add Rule"
                                    color: Style.colors.textButton
                                    font.pixelSize: 13
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    font.bold: true
                                }
                            }
                        }

                        onClicked: {
                            addRulePopup.open()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: Style.colors.secondaryBackground
                }

                ListView {
                    id: rulesList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    model: rulesModel
                    currentIndex: 0
                    spacing: 5
                    clip: true

                    delegate: Rectangle {
                        width: rulesList.width
                        height: 25
                        color: "transparent"
                        radius: 5

                        RowLayout {
                            anchors.fill: parent
                            spacing: 10

                            Rectangle {
                                Layout.preferredWidth: 3
                                Layout.preferredHeight: 15
                                Layout.alignment: Qt.AlignLeft
                                color: ruleColor
                                radius: 5
                            }

                            Text {
                                text: name
                                font.family: Style.fontTypes.roboto
                                color: Style.colors.placeholderText
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: 11
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 1
                                color: Style.colors.secondaryBackground
                            }

                            Text {
                                text: "0"
                                font.family: Style.fontTypes.roboto
                                color: Style.colors.placeholderText
                                Layout.alignment: Qt.AlignLeft
                                font.pixelSize: 11
                            }
                        }

                        MouseArea {
                            anchors.fill: parent

                            cursorShape: "PointingHandCursor"

                            onClicked: {
                                stackLayout.currentIndex = index
                            }
                        }
                    }
                }

            }
        }

        // Right column - showing settings for each rule
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Style.colors.primaryBackground

            StackLayout {
                id: stackLayout

                anchors.fill: parent
                anchors.margins: 10
            }
        }
    }


    /* Functions
     * ****************************************************************************************/

}
