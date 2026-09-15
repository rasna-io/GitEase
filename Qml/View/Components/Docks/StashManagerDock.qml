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

    onVisibleChanged: {
        if (visible)
            root.updateStashes()
    }

    /* Children
     * ****************************************************************************************/
    content: ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: Style.dp(10)
        anchors.rightMargin: Style.dp(10)
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
                        description: "Shelved changes appear here, one card per stash with the branch, base commit and file count. Apply keeps the stash in the list, Pop applies it and removes it, Drop deletes it permanently, and View diff previews its files."
                    },
                    {
                        targetProvider: function() { return actionBtn },
                        icon: Style.icons.plus,
                        title: "Create a Stash",
                        description: "Shelve your current uncommitted changes so you can switch branches or pull cleanly, then bring them back later.",
                        commands: [{ command: "git stash" }]
                    },
                    {
                        targetProvider: function() { return dropAllBtn },
                        icon: Style.icons.trash,
                        title: "Drop All Stashes",
                        description: "Deletes every stash in this repository at once. The shelved changes are gone for good, so use it only to clean up stashes you no longer need.",
                        commands: [{ command: "git stash clear" }]
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

        ContextMenu {
            id: itemContextMenu
            parent: Overlay.overlay
            width: 200
        }

        ListView {
            id: stashListView
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(contentHeight, Style.dp(300))
            spacing: Style.dp(6)
            clip: true
            model: root.stashes

            delegate: StashCard {
                width: stashListView.width
                height: implicitHeight

                stashRef:   "stash@{%1}".arg(modelData.index)
                message:    modelData.message || ""
                branchName: root.stashBranch(modelData)
                baseId:     root.stashBaseId(modelData)
                fileCount:  modelData.fileCount !== undefined ? modelData.fileCount : -1
                dateTime:   modelData.dateTime || null

                selected: !!root.selectedStash && root.selectedStash.index === modelData.index

                onApplyClicked:    root.applyStash(modelData)
                onPopClicked:      root.popStash(modelData)
                onDropClicked:     root.dropStash(modelData)
                onViewDiffClicked: root.openPreview(modelData)

                onMenuRequested: (overlayPosition) => {
                    itemContextMenu.menuModel = root.buildStashMenu(modelData)
                    itemContextMenu.x = overlayPosition.x
                    itemContextMenu.y = overlayPosition.y
                    itemContextMenu.open()
                }
            }

            onContentHeightChanged: root.pageScrollBlocking = stashListView.contentHeight > stashListView.height + 1
        }

        DashedButton {
            id: actionBtn
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(2)

            enabled: root.canStash

            text: "Add Stash"

            onClicked: root.openAddEditPopup()
        }

        DashedButton {
            id: dropAllBtn
            Layout.fillWidth: true

            enabled: root.stashes.length > 0

            iconText: Style.icons.trash
            text: "Drop all stashes"

            textColor: dropAllBtn.hovered && dropAllBtn.enabled ? Style.colors.dashedButtonTextDanger
                                                                : Style.colors.dashedButtonText
            borderColor: dropAllBtn.hovered && dropAllBtn.enabled ? Style.colors.dashedButtonBorderDanger
                                                                  : Style.colors.dashedButtonBorder

            onClicked: root.dropAllStashes()
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

    function popStash(stashEntry) {
        let result = root.stashController.pop(stashEntry.index, true)
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

    function applyStash(stashEntry) {
        let result = root.stashController.apply(stashEntry.index, true)
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

    function dropStash(stashEntry) {
        let result = root.stashController.remove(stashEntry.index)
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

    //! Drops every stash, highest index first so the remaining indices stay valid
    function dropAllStashes() {
        if (!root.stashController || root.stashes.length === 0)
            return

        let total = root.stashes.length

        for (let i = total - 1; i >= 0; --i) {
            let result = root.stashController.remove(i)
            if (!result.success) {
                if (root.notificationController) {
                    root.notificationController.error(result.errorMessage || "Failed to drop all stashes",
                                                     "Stash Error", 5000)
                }
                root.updateStashes()
                return
            }
        }

        if (root.notificationController) {
            root.notificationController.success(total === 1 ? "1 stash dropped"
                                                           : total + " stashes dropped",
                                               "Stash", 3000)
        }

        root.updateStashes()
    }

    function buildStashMenu(stashEntry) {
        return [
            { text: "View diff", icon: Style.icons.file,  action: function() { root.openPreview(stashEntry) } },
            { text: "Pop",       icon: Style.icons.undo,  action: function() { root.popStash(stashEntry) } },
            { text: "Apply",     icon: Style.icons.check, action: function() { root.applyStash(stashEntry) } },
            { text: "Drop",      icon: Style.icons.trash, action: function() { root.dropStash(stashEntry) } }
        ]
    }

    //! The branch the stash was taken on, parsed out of git's "WIP on <branch>: ..." message
    function stashBranch(stashEntry) {
        if (!stashEntry || !stashEntry.message)
            return ""

        let match = /^(?:WIP on|On) ([^:]+):/.exec(stashEntry.message)
        return match ? match[1].trim() : ""
    }

    function stashBaseId(stashEntry) {
        if (!stashEntry)
            return ""

        let id = stashEntry.parentId || stashEntry.id || ""
        return id.substring(0, 7)
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
