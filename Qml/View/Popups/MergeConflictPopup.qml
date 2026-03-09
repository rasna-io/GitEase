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

    width: 900
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

            /* Header */

            RowLayout {

                Layout.fillWidth: true

                Text {
                    Layout.fillWidth: true
                    text: "Merge Conflicts"
                    color: Style.colors.foreground
                    font.bold: true
                    font.pixelSize: 12
                }
            }

            /* Main Panel */

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

                    /* File List */

                    ListView {

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

                                text: modelData.path
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

                Layout.fillWidth: true

                Item { Layout.fillWidth: true }

                Button {

                    text: "Continue Merge"
                    enabled: root.canContinueMerge

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
