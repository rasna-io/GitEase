import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * CheckoutBranchSelectorPopup
 * Shown when a commit has multiple distinct branches so the user can pick which one to check out.
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var branches: []

    /* Signals
     * ****************************************************************************************/
    signal branchSelected(string branchName)

    /* Object Properties
     * ****************************************************************************************/
    width: 400
    height: Math.min(contentColumn.implicitHeight + 2, 520)
    padding: 0

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            id: contentColumn
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            spacing: 0

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 56

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 20
                    anchors.rightMargin: 16
                    spacing: 10

                    Text {
                        text: Style.icons.gitBranch
                        font.family: Style.fontTypes.font6ProSolid
                        font.pixelSize: 16
                        color: Style.colors.accent
                    }

                    Text {
                        text: "Select Branch"
                        color: Style.colors.foreground
                        font.family: Style.fontTypes.roboto
                        font.bold: true
                        font.pixelSize: 15
                        Layout.fillWidth: true
                    }
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 20
                Layout.rightMargin: 20
                Layout.bottomMargin: 12
                text: "Multiple branches point to this commit. Choose which one to check out."
                color: Style.colors.mutedText
                font.family: Style.fontTypes.roboto
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                height: 1
                color: Style.colors.primaryBorder
            }

            ListView {
                id: branchList
                Layout.fillWidth: true
                Layout.preferredHeight: Math.min(contentHeight, 320)
                Layout.topMargin: 8
                Layout.bottomMargin: 8
                model: root.branches
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                delegate: Item {
                    width: branchList.width
                    height: 40

                    readonly property bool isHovered: rowMouse.containsMouse

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        radius: 6
                        color: isHovered ? Style.colors.surfaceLight : "transparent"

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 10

                            Text {
                                text: Style.icons.gitBranch
                                font.family: Style.fontTypes.font6ProSolid
                                font.pixelSize: 12
                                color: Style.colors.accent
                                Layout.preferredWidth: 16
                                horizontalAlignment: Text.AlignHCenter
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: 13
                                color: Style.colors.foreground
                                elide: Text.ElideMiddle
                            }

                            Text {
                                text: Style.icons.arrowRight
                                font.family: Style.fontTypes.font6ProSolid
                                font.pixelSize: 11
                                color: Style.colors.accent
                                opacity: isHovered ? 1.0 : 0.0
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 120
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: rowMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.branchSelected(modelData)
                            root.close()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.rightMargin: 4
                height: 1
                color: Style.colors.primaryBorder
            }

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: 56

                Button {
                    anchors.right: parent.right
                    anchors.rightMargin: 30
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Cancel"
                    Material.foreground: Style.colors.foreground

                    background: Rectangle {
                        implicitWidth: 90
                        implicitHeight: 34
                        color: parent.hovered ? Style.colors.surfaceLight : "transparent"
                        border.color: Style.colors.primaryBorder
                        radius: 6
                    }

                    onClicked: root.close()
                }
            }
        }
    }

    onAboutToHide: {
        root.branches = []
    }
}
