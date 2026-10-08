import QtQuick
import QtQuick.Layouts

import GitEase
import GitEase_Style

import "qrc:/GitEase/Qml/Core/Scripts/AsyncGit.js" as AsyncGit

/*! ***********************************************************************************************
 * ChangesFileLists
 * Two stacked file lists used in Committing page:
 *   - Staged Changes (top)
 *   - Unstaged Changes (bottom)
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property StatusController        statusController:        null
    property NotificationController  notificationController:  null
    property StashController         stashController:         null
    property GuideController         guideController:         null

    property var unstagedModel: []
    property var stagedModel: []
    property string currentFile: ""
    property int currentFileStatus: -1
    property var showSaveDialog

    property int statusToken: 0

    /* Signals
     * ****************************************************************************************/
    signal fileSelected(string filePath, bool isStaged)
    signal changesAborted()

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 1
    implicitHeight: 1

    Component.onCompleted: root.updateStatus()

    Timer {
        id: statusCoalesceTimer
        interval: 16
        repeat: false
        onTriggered: root.requestStatus()
    }

    GuideHoverTrigger {
        guideController: root.guideController
        guideId: "staging_tutorial"
        guideName: "Staging Changes"
        guideIcon: Style.icons.arrowRight
        guidePage: "committing"
        stepsFactory: function() {
            return [
                {
                    targetProvider: function() { return stagedSection },
                    icon: Style.icons.arrowRight,
                    title: "Staged Changes",
                    description: "Files here are queued for your next commit — they will be included in the snapshot. Click any file to preview its diff."
                },
                {
                    targetProvider: function() { return unstagedSection },
                    icon: Style.icons.arrowRight,
                    title: "Unstaged Changes",
                    description: "Files here have local edits not yet marked for commit. Stage individual files from the list, select specific lines in the diff view, or use the header button to stage everything at once."
                }
            ]
        }
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        StagedFileListSection {
            id: stagedSection
            Layout.fillWidth: true
            Layout.fillHeight: wantsFillHeight
            Layout.minimumHeight: 30
            Layout.preferredHeight: expanded ? -1 : 30

            model: root.stagedModel

            onUnstageFileRequested: function(filePath) {
                root.showSaveDialog(
                            () => {
                                let res = statusController.unstageFile(filePath)
                                if (!res.success) {
                                    root.notificationController.error(res.errorMessage || "Failed to unstage file", "Unstage Error", 5000)
                                }
                                root.updateStatus()
                            }
                )
            }

            onOpenFileRequested: function(filePath) {
                root.fileSelected(filePath, true)
            }

            onUnstageAllRequested: function() {
                root.showSaveDialog(
                            () => {
                                let failedFiles = []
                                root.stagedModel.forEach((file)=>{
                                    let res = statusController.unstageFile(file.path)
                                    if (!res.success) {
                                        failedFiles.push(file.path)
                                    }
                                })
                                if (failedFiles.length > 0) {
                                    root.notificationController.error("Failed to unstage some files", "Unstage Error", 5000)
                                } else if (root.unstagedModel.length > 0) {
                                    root.notificationController.success("All files unstaged successfully", "Unstage All", 3000)
                                }
                                root.updateStatus()
                            }
                )
            }

            onStashAllRequested: function() {
                root.showSaveDialog(
                            () => {
                                let message = "Stash staged changes";
                                let result = stashController.save(message, true);

                                if (result.success) {
                                    root.notificationController.success("Changes stashed successfully", "Stash", 3000)
                                    root.updateStatus();
                                } else {
                                    root.notificationController.error(result.errorMessage || "Stash failed", "Stash Error", 5000)
                                    errorMessageLabel.text = result.errorMessage ?? "Stash failed";
                                }
                            }
                )
            }

            onFileSelected: function(filePath) {
                unstagedSection.selectedFilePath = ""
                root.fileSelected(filePath, true)
            }
        }

        UnstagedFileListSection {
            id: unstagedSection
            Layout.fillWidth: true
            Layout.fillHeight: wantsFillHeight
            Layout.minimumHeight: 30
            Layout.preferredHeight: expanded ? -1 : 30

            model: root.unstagedModel

            onStageFileRequested: function(filePath, isDeleted) {
                root.showSaveDialog(
                    () => {
                        root.confirmConflictStaging([filePath], () => {
                            let res = statusController.stageFile(filePath, isDeleted)
                            if (!res.success) {
                                root.notificationController.error(res.errorMessage || "Failed to stage file", "Stage Error", 5000)
                            }
                            root.updateStatus()
                        })
                    }
                )
            }

            onStashFileRequested: function(filePath) {
                let message = "Stashing file: " + filePath
                let res = stashController.stashFile(filePath, message)
                if (res.success) {
                    root.notificationController.success("File stashed: " + filePath, "Stash File", 3000)
                } else {
                    root.notificationController.error(res.errorMessage || "Failed to stash file", "Stash Error", 5000)
                }
                root.updateStatus()
            }

            onDiscardFileRequested: function(filePath) {
                function discardFile() {
                    let res = statusController.revertFile(filePath)
                    if (res.success) {
                        root.notificationController.success("File changes discarded successfully", "Discard", 3000)
                    } else {
                        root.notificationController.error(res.errorMessage || "Failed to discard file changes", "Discard Error", 5000)
                    }
                    root.updateStatus()
                }

                if(root.currentFile === filePath)
                {
                    root.changesAborted()
                    discardFile()
                    return
                }

                root.showSaveDialog(
                            () => {
                                discardFile()
                            }
                )
            }

            onOpenFileRequested: function(filePath) {
                root.showSaveDialog(
                            () => {
                                root.fileSelected(filePath, false)
                            }
                )
            }

            onStageAllRequested: function() {
                root.showSaveDialog(
                            () => {
                                root.confirmConflictStaging(root.unstagedModel.map(file => file.path), () => {
                                    let res = statusController.stageAll()
                                    if (res.success) {
                                        root.notificationController.success("All files staged successfully", "Stage All", 3000)
                                    } else {
                                        root.notificationController.error(res.errorMessage || "Failed to stage all files", "Stage Error", 5000)
                                    }
                                    root.updateStatus()
                                }, true)
                            }
                )
            }

            onDiscardAllRequested: function() {
                let res = statusController.revertAll()
                if (res.success) {
                    root.notificationController.success("All changes discarded successfully", "Discard All", 3000)
                } else {
                    root.notificationController.error(res.errorMessage || "Failed to discard all changes", "Discard Error", 5000)
                }
                root.updateStatus()
            }

            onStashAllRequested: function() {
                root.showSaveDialog(
                            () => {
                                let message = "Stash unstaged changes"
                                let result = stashController.save(message, false);

                                if (result.success) {
                                    root.notificationController.success("Changes stashed successfully", "Stash", 3000)
                                    root.updateStatus();
                                } else {
                                    root.notificationController.error(result.errorMessage || "Stash failed", "Stash Error", 5000)
                                    errorMessageLabel.text = result.errorMessage ?? "Stash failed";
                                }
                            }
                )
            }

            onFileSelected: function(filePath, fileStatus) {
                stagedSection.selectedFilePath = ""
                root.currentFileStatus = fileStatus
                root.fileSelected(filePath, false)
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: !(stagedSection.wantsFillHeight && unstagedSection.wantsFillHeight)
            Layout.preferredHeight: 0
            visible: true
        }
    }

    Component {
        id: conflictStagingDialogComp
        ConflictConfirmationDialog { }
    }

    /* Functions
     * ****************************************************************************************/
    function updateStatus() {
        statusCoalesceTimer.restart()
    }

    function confirmConflictStaging(paths, stageAction, stagingAll = false) {
        let conflicted = paths.filter(path => root.unstagedModel.some(file => file.path === path && file.isConflicted))
        if (conflicted.length === 0) {
            stageAction()
            return
        }

        let withMarkers = conflicted.filter(path => root.statusController.hasConflictMarkers(path))
        let dialog      = conflictStagingDialogComp.createObject(root)

        const escape  = text => text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
        const tint    = (text, color) => `<span style="color:${color}">${escape(text)}</span>`
        const code    = (text, color) => `<span style="font-family:'${Style.fontTypes.jetBrainsMono}'; ` +
                                         `font-weight:600; color:${color}">${escape(text)}</span>`
        const pathOf  = path => code(path, Style.colors.popupTitleText)

        const markers = code(["<<<<<<<", "=======", ">>>>>>>"].join(String.fromCharCode(0xA0)),
                             Style.colors.conflictMarker)

        if (conflicted.length === 1) {
            dialog.title   = "Mark Conflict as Resolved?"
            dialog.message = withMarkers.length > 0
                    ? `${pathOf(conflicted[0])} still contains conflict markers ${markers}.<br><br>` +
                      "Staging it marks the conflict as resolved. If you commit the file like this, " +
                      "the markers are committed with it."
                    : `${pathOf(conflicted[0])} has no conflict markers left, but Git still lists it ` +
                      "as conflicted.<br><br>" +
                      "Staging it marks the conflict as resolved, using the file exactly as it is now."
        } else {
            const shown = conflicted.slice(0, 5)
            let   list  = shown.map(path => "•&nbsp;&nbsp;" + pathOf(path) +
                                            (withMarkers.includes(path)
                                             ? "&nbsp;&nbsp;" + tint("has markers", Style.colors.conflictMarker)
                                             : ""))

            if (conflicted.length > shown.length)
                list.push(`•&nbsp;&nbsp;and ${conflicted.length - shown.length} more`)

            dialog.title   = "Mark Conflicts as Resolved?"
            dialog.message = `${conflicted.length} conflicted files will be marked as resolved:<br>` +
                             list.join("<br>") + "<br><br>" +
                             (withMarkers.length > 0
                              ? (withMarkers.length === conflicted.length ? "All" : withMarkers.length) +
                                ` of them still contain conflict markers ${markers}. ` +
                                "Committing them like this would commit the markers too."
                              : "None of them has conflict markers left, so each is staged exactly as it is now.")
        }

        dialog.messageFormat = Text.RichText

        dialog.saveTitle       = stagingAll ? "Stage All and Resolve" : "Stage and Resolve"
        dialog.saveDescription = stagingAll ? "Stage every file and mark its conflict resolved"
                                            : "Mark the conflict resolved with the file as it is now"

        dialog.hasSave           = true
        dialog.hasAbort          = false
        dialog.cancelTitle       = "Cancel"
        dialog.cancelDescription = "Keep the conflicts unresolved"

        dialog.saved.connect(stageAction)
        dialog.open()
    }

    function requestStatus() {
        if (!root.statusController)
            return

        let token = ++root.statusToken

        AsyncGit.call(root.statusController, "status", [],
            function (res) {
                if (token !== root.statusToken)
                    return

                if (!res || !res.success || !res.data)
                    return

                root.applyStatus(res.data)
            })
    }

    function applyStatus(files) {
        let unstaged = []
        let staged = []

        files.forEach((file) => {
            if (file.isStaged) {
                staged.push(file)
            }
            if (file.isUnstaged || file.isUntracked) {
                unstaged.push(file)
            }
        })

        root.unstagedModel = unstaged
        root.stagedModel = staged

        let path = ""
        let isStaged = false

        if (root.unstagedModel.length > 0) {
            path = root.unstagedModel[0].path
        } else if (root.stagedModel.length > 0) {
            path = root.stagedModel[0].path
        }

        const targetPath = root.currentFile || path
        isStaged = !(root.unstagedModel.some(file => file.path === targetPath))

        unstagedSection.selectedFilePath = isStaged ? "" : targetPath
        stagedSection.selectedFilePath = isStaged ? targetPath : ""

        root.fileSelected(targetPath, isStaged)
    }
}
