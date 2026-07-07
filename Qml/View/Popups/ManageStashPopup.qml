import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ManageStashPopup
 * ************************************************************************************************/

IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property StashController stashController: null
    property StatusController statusController: null
    property CommitController commitController: null

    property var stashEntry: null
    property var stashFiles: []
    property var stashDiffData: []
    property string selectedFilePath: ""

    /* Object Properties
     * ****************************************************************************************/
    width: 800
    height: 650
    padding: 12

    readonly property bool canPerformAction: stashEntry !== null

    onStashEntryChanged: {
        if (!stashEntry || !statusController) {
            stashFiles = []
            stashDiffData = []
            selectedFilePath = ""
            return
        }

        // Load the list of files for this stash
        let loadFiles = statusController.getCommitFileChanges(stashEntry.id)
        if (loadFiles.success) {
            stashFiles = loadFiles.data

            // Automatically select the first file
            if (stashFiles.length > 0) {
                selectFile(stashFiles[0].path)
            } else {
                stashDiffData = []
                selectedFilePath = ""
            }
        }
    }


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

            RowLayout{
                Layout.fillWidth: true
                Text {
                    Layout.fillWidth: true
                    text: root.stashEntry
                          ? ("stash@{" + root.stashEntry.index + "}  " + (root.stashEntry.message || "WIP"))
                          : "Stash"
                    color: Style.colors.foreground
                    font.family: Style.fontTypes.roboto
                    font.bold: true
                    elide: Text.ElideLeft
                    font.pixelSize: Style.appFont.defaultPt
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

            RowLayout{
                Layout.fillWidth: true
                spacing: 8

                CheckBox {
                    id: reinstateIndexCheck
                    Layout.fillWidth: false
                    text: "Restore Staged / Index State"
                    checked: true

                    font.family: Style.fontTypes.roboto
                    font.pixelSize: Style.appFont.mediumPt

                    Material.accent: Style.colors.accent
                    Material.foreground: Style.colors.foreground

                    palette {
                        text: Style.colors.foreground
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                ActionIconButton {
                    iconText: Style.icons.trash
                    tooltip: "Drop"
                    textColor: Style.colors.deletededFile

                    onClicked: {
                        root.executeAction("remove")
                        root.close()
                    }
                }

                ActionIconButton {
                    iconText: Style.icons.undo
                    tooltip: "Pop"
                    textColor: Style.colors.mutedText

                    onClicked: {
                        root.executeAction("pop")
                        root.close()
                    }
                }

                ActionIconButton {
                    iconText: Style.icons.check
                    tooltip: "Apply"
                    textColor: Style.colors.mutedText

                    onClicked: {
                        root.executeAction("apply")
                        root.close()
                    }
                }
            }

            Rectangle {
                Layout.topMargin: 10
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

                    ListView {
                        Layout.preferredWidth: 240
                        Layout.fillHeight: true
                        clip: true
                        model: root.stashFiles

                        delegate: Rectangle {
                            width: parent.width
                            height: 24
                            radius: 3
                            color: (root.selectedFilePath === modelData.path) ? Style.colors.hoverTitle : "transparent"

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 4
                                anchors.rightMargin: 4
                                spacing: 6

                                Text {
                                    text: root.statusLabel(modelData.deltaStatus)
                                    color: Style.colors.mutedText
                                    font.pixelSize: Style.appFont.microPt
                                    Layout.preferredWidth: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    font.bold: true
                                }

                                Text {
                                    text: modelData.path || ""
                                    color: Style.colors.foreground
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: Style.appFont.h3Pt
                                    Layout.fillWidth: true
                                    elide: Text.ElideMiddle
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: root.selectFile(modelData.path)
                            }
                        }
                    }

                    DiffView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        readOnly: true
                        diffData: root.stashDiffData
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function selectFile(filePath) {
        root.selectedFilePath = filePath
        root.loadDiffForFile()
    }

    function loadDiffForFile() {
        root.stashDiffData = []
        if (!stashEntry || !selectedFilePath || !statusController)
            return

        const parentHash = stashEntry.parentId
                           || (commitController ? commitController.getParentHash(stashEntry.id) : "")

        if (!parentHash)
            return

        let res = statusController.getDiff(parentHash, stashEntry.id, selectedFilePath)
        if (res.success) {
            root.stashDiffData = res.data
        }
    }

    function executeAction(action) {
        if (!stashEntry || !stashController)
            return

        let result = ({ success: false })
        if (action === "apply") {
            result = stashController.apply(stashEntry.index, reinstateIndexCheck.checked)
        } else if (action === "pop") {
            result = stashController.pop(stashEntry.index, reinstateIndexCheck.checked)
        } else if (action === "remove") {
            result = stashController.remove(stashEntry.index)
        }

        if (result.success) {
            // optional: emit signal or callback to parent to refresh list
        }
    }

    function statusLabel(fileOrDelta) {
        switch (fileOrDelta) {
            case GitFileStatus.ADDED:
                return "A"

            case GitFileStatus.DELETED:
                return "D"

            case GitFileStatus.MODIFIED:
                return "M"

            case GitFileStatus.RENAMED:
                return "R"

            default:
                return "?"
        }
    }
}
