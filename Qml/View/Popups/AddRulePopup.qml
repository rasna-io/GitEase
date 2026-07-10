import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * AddRulePopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var rulesModel

    /* Object Properties
     * ****************************************************************************************/
    width: 700
    height: 350
    padding: 20

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 15

            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: "Choose rule type"
                    Layout.fillWidth: true
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 13
                    color: "white"
                    font.bold: true
                }

                Button {
                    implicitHeight: 30
                    Layout.preferredWidth: 20

                    background: Rectangle {
                        radius: 8
                        color: "transparent"
                    }

                    contentItem: Item {
                        anchors.fill: parent

                        Text {
                            anchors.centerIn: parent
                            text: "X"
                            color: Style.colors.textButton
                            font.pixelSize: 13
                            font.bold: true
                        }
                    }

                    onClicked: {
                        root.close()
                    }
                }
            }


            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.secondaryBackground
            }

            GridView {
                id: gridView
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                model: rulesModel

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                cellWidth: width / 2
                cellHeight: 80

                delegate: Item {
                    width: gridView.cellWidth
                    height: gridView.cellHeight

                    Rectangle {
                        width: gridView.cellWidth - 10
                        height: gridView.cellHeight - 10
                        color: Style.colors.secondaryBackground
                        radius: 5

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: "PointingHandCursor"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.left: parent.left
                            anchors.leftMargin: 8
                            spacing: 10

                            Rectangle {
                                width: 30
                                height: 30
                                radius: 5
                                color: ruleColor
                            }

                            ColumnLayout {
                                Text {
                                    text: name
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 12
                                    color: "white"
                                    font.bold: true
                                }

                                ScrollingText {
                                    text: description
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 10
                                    color: Style.colors.mutedText
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
