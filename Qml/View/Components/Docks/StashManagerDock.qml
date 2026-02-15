import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style_Impl
import GitEase_Style
import GitEase

/*! ***********************************************************************************************
 * StashManagerDock
 * ************************************************************************************************/

UtilitiesCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property StashController        stashController:        null
    property CommitController       commitController:       null
    property StatusController       statusController:       null
    property AddStashPopup          addStashPopup:          null
    property NotificationController notificationController: null
    property ManageStashPopup       manageStashPopup:       null
    
    property var                    stashes:                []
    property var                    selectedStash:          null
    property var                    stashFiles:             []
    property var                    stashDiffData:          []
    property string                 selectedFilePath:       ""

    property var previewStash: null

    /* Object Properties
     * ****************************************************************************************/
    title: "Stash Manager"
    icon: Style.icons.archive

    /* Children
     * ****************************************************************************************/
    content: ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 8

        Connections {
            target: root
            function onStashControllerChanged() {
                root.updateStashes(true)
            }
        }

        Connections {
            target: root.addStashPopup
            function onAboutToHide() {
                root.updateStashes()
            }
        }

        Connections {
            target: root.manageStashPopup
            function onAboutToHide() {
                root.updateStashes()
            }
        }

        ListView {
            id: stashListView
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 6
            clip: true
            model: root.stashes

            delegate: Rectangle {
                width: stashListView.width
                height: 50
                radius: 5
                property bool selected: root.selectedStash && root.selectedStash.index === modelData.index
                color: selected ? Style.colors.hoverTitle : Style.colors.secondaryBackground

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 8
                    spacing: 6

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        Text {
                            Layout.fillWidth: true
                            text: modelData.message || qsTr("WIP on %1").arg(modelData.author || "unknown")
                            color: Style.colors.foreground
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 11
                            elide: Text.ElideMiddle
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.dateTime ? Qt.formatDateTime(modelData.dateTime, "MMM dd, yyyy hh:mm") : ""
                            color: Style.colors.mutedText
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 9
                            elide: Text.ElideRight
                        }
                    }

                    Row {
                        spacing: 2

                        ActionIconButton {
                            iconText: Style.icons.file
                            tooltip: "Open"
                            textColor: Style.colors.mutedText
                            onClicked: root.openPreview(modelData)
                        }

                        ActionIconButton {
                            iconText: Style.icons.undo
                            tooltip: "Pop"
                            textColor: Style.colors.mutedText
                            onClicked: {
                                let result = stashController.pop(modelData.index, true)
                                if (result.success) {
                                    if (root.notificationController) {
                                        root.notificationController.success("Stash popped successfully", "Stash", 3000)
                                    }
                                    content.update()
                                } else {
                                    if (root.notificationController) {
                                        root.notificationController.error(result.errorMessage || "Failed to pop stash", "Stash Error", 5000)
                                    }
                                }
                            }
                        }

                        ActionIconButton {
                            iconText: Style.icons.check
                            tooltip: "Apply"
                            textColor: Style.colors.mutedText
                            onClicked: {
                                let result = stashController.apply(modelData.index, true)
                                if (result.success) {
                                    if (root.notificationController) {
                                        root.notificationController.success("Stash applied successfully", "Stash", 3000)
                                    }
                                    content.update()
                                } else {
                                    if (root.notificationController) {
                                        root.notificationController.error(result.errorMessage || "Failed to apply stash", "Stash Error", 5000)
                                    }
                                }
                            }
                        }

                        ActionIconButton {
                            iconText: Style.icons.trash
                            tooltip: "Drop"
                            textColor: Style.colors.deletededFile
                            onClicked: {
                                let result = stashController.remove(modelData.index)
                                if (result.success) {
                                    if (root.notificationController) {
                                        root.notificationController.success("Stash removed successfully", "Stash", 3000)
                                    }
                                    content.update()
                                } else {
                                    if (root.notificationController) {
                                        root.notificationController.error(result.errorMessage || "Failed to remove stash", "Stash Error", 5000)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Button {
            Layout.fillWidth: true
            implicitHeight: 38

            background: Rectangle {
                radius: 8
                color: enabled ? Style.colors.accent : Style.colors.disabledButton
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
                        color: Style.colors.secondaryForeground
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Stash"
                        color: Style.colors.secondaryForeground
                        font.pixelSize: 13
                    }
                }
            }

            onClicked: root.openAddEditPopup()
        }
    }

    /* Functions
     * ****************************************************************************************/
    function openAddEditPopup() {
        if (!root.addStashPopup)
            return

        root.addStashPopup.stashController = root.stashController
        root.addStashPopup.statusController = root.statusController
        root.addStashPopup.open()
    }

    function openPreview(stashEntry) {
        if (!root.manageStashPopup)
            return

        root.manageStashPopup.stashController = root.stashController
        root.manageStashPopup.statusController = root.statusController
        root.manageStashPopup.commitController = root.commitController
        root.manageStashPopup.stashEntry = stashEntry
        root.manageStashPopup.open()
    }

    function updateStashes() {
        if (!root.stashController) {
            root.stashes = []
            root.selectedStash = null
            root.stashFiles = []
            root.stashDiffData = []
            return
        }

        let result = root.stashController.list()
        if (!result.success) {
            root.stashes = []
            root.selectedStash = null
            root.stashFiles = []
            root.stashDiffData = []
            return
        }

        root.stashes = result.data

        root.selectedStash = null
        root.previewStash = null
        root.stashFiles = []
        root.stashDiffData = []
    }

    function selectStash(stashEntry) {
        root.selectedStash = stashEntry
        root.selectedFilePath = ""
        root.stashDiffData = []
        root.loadSelectedStashFiles()
    }

    function loadSelectedStashFiles() {
        root.stashFiles = []
        if (!root.selectedStash || !root.statusController || !root.selectedStash.id)
            return

        let res = root.statusController.getCommitFileChanges(root.selectedStash.id)
        if (!res.success)
            return

        root.stashFiles = res.data
        if (root.stashFiles.length > 0) {
            root.selectStashFile(root.stashFiles[0].path)
        }
    }

    function selectStashFile(filePath) {
        root.selectedFilePath = filePath
        root.loadSelectedDiff()
    }

    function loadSelectedDiff() {
        root.stashDiffData = []
        if (!root.selectedStash || !root.selectedFilePath || !root.statusController)
            return

        const parentHash = root.selectedStash.parentId
                           || (root.commitController ? root.commitController.getParentHash(root.selectedStash.id) : "")

        if (!parentHash)
            return

        let res = root.statusController.getDiff(parentHash, root.selectedStash.id, root.selectedFilePath)
        if (res.success) {
            root.stashDiffData = res.data
        }
    }

    function executeStashAction(action, stashEntry, reinstateIndex) {
        if (!stashEntry || !root.stashController)
            return

        let result = ({ success: false })
        if (action === "apply") {
            result = root.stashController.apply(stashEntry.index, reinstateIndex)
        } else if (action === "pop") {
            result = root.stashController.pop(stashEntry.index, reinstateIndex)
        } else if (action === "remove") {
            result = root.stashController.remove(stashEntry.index)
        }

        if (result.success) {
            root.updateStashes()
        }
    }

    function statusLabel(deltaStatus) {
        switch (deltaStatus) {
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

    Component.onCompleted: updateStashes()
}
