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
        let res = statusController.getCommitFileChanges(stashEntry.id)
        if (res.success) {
            stashFiles = res.data

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
            spacing: 20
            anchors.fill: parent
            anchors.margins: 20

            Text {
                Layout.fillWidth: true
                text: root.stashEntry
                      ? ("stash@{" + root.stashEntry.index + "}  " + (root.stashEntry.message || "WIP"))
                      : "Stash"
                color: Style.colors.foreground
                font.family: Style.fontTypes.roboto
                font.bold: true
                font.pixelSize: 16
                Layout.alignment: Qt.AlignHCenter
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

                    ListView {
                        Layout.preferredWidth: 220
                        Layout.fillHeight: true
                        clip: true
                        model: root.stashFiles

                        delegate: Rectangle {
                            width: parent.width
                            height: 22
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
                                    font.pixelSize: 11
                                    Layout.preferredWidth: 18
                                }

                                Text {
                                    text: modelData.path || ""
                                    color: Style.colors.foreground
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 15
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

            CheckboxItem {
                id: reinstateIndexCheck
                Layout.fillWidth: true
                title: "Restore Staged / Index State"
                description: "Reapply the stash including staged changes"
                checked: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 38

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
                                text: "Cancel"
                                color: Style.colors.secondaryForeground
                                font.pixelSize: 13
                            }
                        }
                    }

                    onClicked: root.close()
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 38

                    background: Rectangle {
                        radius: 8
                        color: enabled ? Style.colors.accent
                                       : Style.colors.disabledButton
                    }

                    contentItem: Item {
                        anchors.fill: parent
                        Row {
                            spacing: 10
                            anchors.centerIn: parent

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Style.icons.undo
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: 12
                                color: Style.colors.secondaryForeground
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Pop"
                                color: Style.colors.secondaryForeground
                                font.pixelSize: 13
                            }
                        }
                    }

                    onClicked: {
                        root.executeAction("pop")
                        root.close()
                    }
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 38

                    background: Rectangle {
                        radius: 8
                        color: enabled ? Style.colors.accent
                                       : Style.colors.disabledButton
                    }

                    contentItem: Item {
                        anchors.fill: parent
                        Row {
                            spacing: 10
                            anchors.centerIn: parent

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Style.icons.check
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: 12
                                color: Style.colors.secondaryForeground
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Apply"
                                color: Style.colors.secondaryForeground
                                font.pixelSize: 13
                            }
                        }
                    }

                    onClicked: {
                        root.executeAction("apply")
                        root.close()
                    }
                }

                Button {
                    Layout.fillWidth: true
                    implicitHeight: 38

                    background: Rectangle {
                        radius: 8
                        color: enabled ? Style.colors.deletededFile
                                       : Style.colors.disabledButton
                    }

                    contentItem: Item {
                        anchors.fill: parent
                        Row {
                            anchors.centerIn: parent
                            spacing: 10

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: Style.icons.trash
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: 12
                                color: Style.colors.secondaryForeground
                            }

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: "Drop"
                                color: Style.colors.secondaryForeground
                                font.pixelSize: 13
                            }
                        }
                    }

                    onClicked: {
                        root.executeAction("remove")
                        root.close()
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

    function statusLabel(deltaStatus) {
        switch (deltaStatus) {
        case GitFileStatus.ADDED: return "A"
        case GitFileStatus.DELETED: return "D"
        case GitFileStatus.MODIFIED: return "M"
        case GitFileStatus.RENAMED: return "R"
        default: return "?"
        }
    }
}
