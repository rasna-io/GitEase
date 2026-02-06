import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style_Impl
import GitEase_Style
import GitEase

// import "../Stash"

/*! ***********************************************************************************************
 * StashManager
 * Manage Git stashes - save, list, apply, and remove stashes
 * ************************************************************************************************/

Rectangle {
    id: root

    property StashController stashController: null

    /* Property Declarations
     * ****************************************************************************************/
    property int currentIndex: 0

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground
    radius: 7
    border.width: 1
    border.color: Style.colors.primaryBorder

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/
    ButtonGroup {
        id: headerButtonGroup
        exclusive: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            spacing: 10

            Label {
                text: Style.icons.archive
                color: Style.colors.accent
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: 15
            }

            Label {
                text: "Stash Manager"
                color: Style.colors.foreground
                font.family: Style.fontTypes.roboto
                font.pixelSize: 13
                font.bold: true
            }
        }

        // View Control
        Rectangle {
            id: viewControl
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 10
            color: Style.colors.cardBackground

            RowLayout {
                anchors.fill: parent
                spacing: 4
                anchors.margins: 5

                Button {
                    id: createBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    topInset: 0
                    bottomInset:0
                    verticalPadding: 6

                    checkable: true
                    checked: root.currentIndex === 0
                    ButtonGroup.group: headerButtonGroup

                    background: Rectangle {
                        radius: viewControl.radius
                        color: createBtn.checked ? Style.colors.primaryBackground : "transparent"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.currentIndex = 0
                    }



                    contentItem: Row {
                        spacing: 8
                        anchors.centerIn: parent

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Style.icons.plus
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: 12
                            color: Style.colors.foreground
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Create"
                            font.pixelSize: Style.appFont.h3Pt
                            color: Style.colors.foreground
                        }
                    }
                }

                Button {
                    id: manageBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    topInset: 0
                    bottomInset:0
                    verticalPadding: 6

                    checkable: true
                    checked: root.currentIndex === 1
                    ButtonGroup.group: headerButtonGroup

                    background: Rectangle {
                        radius: viewControl.radius
                        color: manageBtn.checked ? Style.colors.primaryBackground : "transparent"
                    }

                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.currentIndex = 1
                    }



                    contentItem: Row {
                        spacing: 8
                        anchors.centerIn: parent

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Style.icons.archive
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: 12
                            color: Style.colors.foreground
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Manage"
                            font.pixelSize: Style.appFont.h3Pt
                            color: Style.colors.foreground
                        }
                    }
                }
            }
        }

        // Content Area
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentIndex

            CreateStashView {
                stashController: root.stashController
            }

            ManageStashesView {
                stashController: root.stashController
            }
        }
    }
}

