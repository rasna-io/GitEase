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
    property GuideController        guideController:        null

    property var                    stashes:                []
    property var                    selectedStash:          null
    property var                    stashFiles:             []
    property var                    stashDiffData:          []
    property string                 selectedFilePath:       ""

    property var previewStash: null

    property bool canStash: false

    /* Object Properties
     * ****************************************************************************************/
    title: "Stash Manager"
    icon: Style.icons.archive
    badgeCount: root.stashes.length

    /* Children
     * ****************************************************************************************/
    content: ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 6

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "stash_manager_tutorial"
            guideName: "Stash Manager"
            guideIcon: Style.icons.archive
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return stashListView },
                        icon: Style.icons.archive,
                        title: "Your Stashes",
                        description: "Shelved changes appear here. Open previews the stash's files, Pop applies it and removes it from the list, Apply keeps it in the list, and the trash icon drops it permanently."
                    },
                    {
                        targetProvider: function() { return actionBtn },
                        icon: Style.icons.plus,
                        title: "Create a Stash",
                        description: "Shelve your current uncommitted changes so you can switch branches or pull cleanly, then bring them back later.",
                        commands: [{ command: "git stash" }]
                    }
                ]
            }
        }

        Connections {
            target: root
            function onStashControllerChanged() {
                root.updateStashes(true)
            }
        }

        Connections {
            target: root.stashController

            function onCurrentRepoChanged() {
                root.updateStashes()
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
            Layout.preferredHeight: Math.min(contentHeight, 220)
            spacing: 4
            clip: true
            model: root.stashes

            delegate: Rectangle {
                width: stashListView.width
                height: Style.dp(35)
                radius: 4
                property bool selected: root.selectedStash && root.selectedStash.index === modelData.index
                color: selected ? Style.colors.hoverTitle : Style.colors.secondaryBackground

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 6
                    spacing: 4

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1
                        ScrollingText {
                            Layout.fillWidth: true
                            text: modelData.message || qsTr("WIP on %1").arg(modelData.author || "unknown")
                            color: Style.colors.foreground
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: Style.appFont.smallPt
                        }
                        Text {
                            Layout.fillWidth: true
                            text: modelData.dateTime ? Qt.formatDateTime(modelData.dateTime, "MMM dd, yyyy hh:mm") : ""
                            color: Style.colors.mutedText
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: Style.appFont.captionPt
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
                                    root.updateStashes()
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
                                    root.updateStashes()
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
                                    root.updateStashes()
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

            onContentHeightChanged: root.pageScrollBlocking = stashListView.contentHeight > stashListView.height + 1
        }

        IconButton {
            id: actionBtn
            Layout.fillWidth: true
            implicitHeight: Style.dp(25)

            enabled: root.canStash

            display: IconButton.TextBesideIcon
            icon.name: Style.icons.plus
            icon.width: Style.appFont.smallPt
            icon.height: Style.appFont.smallPt
            icon.color: Style.colors.textButton
            text: "Stash"
            font.pixelSize: Style.appFont.mediumPt

            background: Rectangle {
                radius: Style.dp(4)
                color: actionBtn.enabled ? (actionBtn.hovered ? Style.colors.accentHover : Style.colors.accent)
                                            : Style.colors.disabledButton
            }

            onClicked: root.openAddEditPopup()
        }
    }

    /* Functions
     * ****************************************************************************************/
    function updateCanStash() {
        root.canStash = false

        if (!root.statusController)
            return

        let res = root.statusController.status()
        if (!res.success)
            return

        for (let i = 0; i < res.data.length; ++i) {
            let file = res.data[i]
            if (file.isStaged || file.isUnstaged || file.isUntracked) {
                root.canStash = true
                return
            }
        }
    }


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

            root.updateCanStash()
            return
        }

        let result = root.stashController.list()
        if (!result.success) {
            root.stashes = []
            root.selectedStash = null
            root.stashFiles = []
            root.stashDiffData = []

            root.updateCanStash()
            return
        }

        root.stashes = result.data

        root.selectedStash = null
        root.previewStash = null
        root.stashFiles = []
        root.stashDiffData = []

        root.updateCanStash()
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
