import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import GitEaseOrganizationRulesPlugin
import "qrc:/GitEase/Qml/View/Popups"

/*! ***********************************************************************************************
 * AddRulePopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var categoriesModel

    /* Signals
     * ****************************************************************************************/
    signal categoryClicked(int index)

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
                    font.family: Style.fontTypes.inter
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

                model: categoriesModel

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

                            onClicked: {
                                root.categoryClicked(index)
                                close()
                            }
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
                                color: modelData.color
                            }

                            ColumnLayout {
                                Text {
                                    text: modelData.name
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: 12
                                    color: "white"
                                    font.bold: true
                                }

                                ScrollingText {
                                    text: modelData.description
                                    font.family: Style.fontTypes.inter
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
