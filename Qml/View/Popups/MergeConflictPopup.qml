import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * MergeConflictPopup
 * ************************************************************************************************/

IPopup {

    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property MergeController mergeController: null
    property ConflictController conflictController: null
    property NotificationController notificationController: null

    property var conflicts: []
    property var selectedConflict: null
    property string selectedFilePath: ""

    /* Object Properties
     * ****************************************************************************************/

    width: 800
    height: 650
    padding: 12

    readonly property bool canContinueMerge: conflicts.length === 0

    onOpened: loadConflicts()

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            spacing: 8
            anchors.fill: parent
            anchors.margins: 20

            RowLayout {

                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Merge Conflicts"
                    color: Style.colors.foreground
                    font.bold: true
                    font.pixelSize: 12
                }

                // Close Button
                WindowsButton {
                    id: closeButton

                    Material.accent: Style.colors.windowsClose
                    content: Item {
                        anchors.centerIn: parent
                        width: 10
                        height: 10

                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                            anchors.centerIn: parent
                            rotation: 45
                        }

                        Rectangle {
                            width: 12
                            height: 2
                            radius: 1
                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                            anchors.centerIn: parent
                            rotation: -45
                        }
                    }
                    onClicked: root.close()
                }
            }

            Rectangle {

                Layout.fillWidth: true
                Layout.fillHeight: true

                radius: 6
                color: Style.colors.secondaryBackground
                border.width: 1
                border.color: Style.colors.primaryBorder

                RowLayout {

                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 8

                    Rectangle{
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        radius: 4
                        color: Style.colors.primaryBackground
                        border.width: 1
                        border.color: Style.colors.primaryBorder

                        ColumnLayout{
                            anchors.fill: parent
                            anchors.margins: 6

                            Text {
                                text: "Conflicted files"
                                font.bold: true
                                color: Style.colors.foreground
                            }

                            ListView {
                                id: listView
                                Layout.preferredWidth: 240
                                Layout.fillHeight: true

                                model: root.conflicts

                                delegate: Rectangle {
                                    width: parent.width
                                    height: 24
                                    radius: 3
                                    color: root.selectedFilePath === modelData.path
                                           ? Style.colors.hoverTitle
                                           : "transparent"

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 6
                                        Layout.fillWidth: true

                                        text: listView.currentIndex + 1 + ") " + modelData.path || ""
                                        font.family: Style.fontTypes.roboto
                                        color: Style.colors.foreground
                                        font.pixelSize: 13
                                        elide: Text.ElideMiddle
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: root.selectFile(modelData)
                                    }
                                }
                            }
                        }
                    }

                    /* OURS PANEL */
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        radius: 4
                        color: Style.colors.primaryBackground
                        border.width: 1
                        border.color: Style.colors.primaryBorder

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6

                            Text {
                                text: "Current (ours)"
                                font.bold: true
                                color: Style.colors.foreground
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TextArea {

                                    readOnly: true
                                    wrapMode: TextEdit.NoWrap
                                    text: root.selectedConflict
                                          ? root.selectedConflict.ourContent
                                          : ""
                                }
                            }

                            Button {
                                text: "Use Current"
                                flat: true
                                Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                                background: Rectangle {
                                    color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                                    border.color: Style.colors.accent
                                    radius: 5
                                }

                                onClicked: {
                                    if (!root.selectedConflict)
                                        return

                                    conflictController.acceptConflictOurs(
                                                root.selectedConflict.path
                                                )

                                    root.loadConflicts()
                                }
                            }
                        }
                    }

                    /* THEIRS PANEL */
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        radius: 4
                        color: Style.colors.primaryBackground
                        border.width: 1
                        border.color: Style.colors.primaryBorder

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 6

                            Text {
                                text: "Incoming (theirs)"
                                font.bold: true
                                color: Style.colors.foreground
                            }

                            ScrollView {
                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                TextArea {

                                    readOnly: true
                                    wrapMode: TextEdit.NoWrap
                                    text: root.selectedConflict
                                          ? root.selectedConflict.theirContent
                                          : ""
                                }
                            }

                            Button {
                                text: "Use Incoming"
                                flat: true
                                Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                                background: Rectangle {
                                    color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                                    border.color: Style.colors.accent
                                    radius: 5
                                }

                                onClicked: {
                                    if (!root.selectedConflict)
                                        return

                                    conflictController.acceptConflictTheirs(
                                                root.selectedConflict.path
                                                )

                                    root.loadConflicts()
                                }
                            }
                        }
                    }
                }
            }

            /* Bottom Actions */
            RowLayout {
                Item {
                    Layout.fillWidth: true
                }

                Button {
                    text: "Continue Merge"
                    enabled: root.canContinueMerge

                    flat: true
                    Material.foreground: hovered & enabled ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered & enabled ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }

                    onClicked: {
                        let res = mergeController.continueMerge()

                        if (res.success)
                            root.close()
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/

    function loadConflicts() {
        if (!conflictController)
            return

        let res = conflictController.getMergeConflicts()

        if (!res.success) {
            if (notificationController)
                notificationController.error(res.errorMessage, "Conflicts", 4000)
            return
        }
        conflicts = res.data || []
    }

    function selectFile(conflictEntry) {
        root.selectedConflict = conflictEntry
        root.selectedFilePath = conflictEntry.path
    }
}
