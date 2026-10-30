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

    property var bulkJobs: []
    readonly property var activeRepo: root.statusController ? root.statusController.currentRepo : null
    readonly property var bulkJob: root.bulkJobs.find(job => job.repo === root.activeRepo) || null
    property var loadedRepo: null
    readonly property bool statusLoading: root.activeRepo !== null && root.loadedRepo !== root.activeRepo
    readonly property bool listsBusy: root.bulkJob !== null || root.statusLoading
    readonly property string busyText: root.bulkJob ? root.bulkJob.text : "Loading changes"
    property bool busyVisible: false
    readonly property int fillingSections: (stagedSection.wantsFillHeight ? 1 : 0) + (unstagedSection.wantsFillHeight ? 1 : 0)
    readonly property real fixedHeight: (stagedSection.wantsFillHeight ? 0 : stagedSection.implicitHeight) +
                                        (unstagedSection.wantsFillHeight ? 0 : unstagedSection.implicitHeight)
    readonly property real fillHeight: root.fillingSections > 0 ? Math.max(0, (root.height - root.fixedHeight) / root.fillingSections) : 0
    property bool resizing: false

    /* Signals
     * ****************************************************************************************/
    signal fileSelected(string filePath, bool isStaged)
    signal changesAborted()

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 1
    implicitHeight: 1

    onHeightChanged: {
        root.resizing = true
        resizeSettleTimer.restart()
    }

    onListsBusyChanged: {
        if(!root.listsBusy) {
            root.busyVisible = false
        }
    }

    Component.onCompleted: root.updateStatus()

    Connections {
        target: root.statusController

        function onCurrentRepoChanged() {
            root.updateStatus()
        }
    }

    Timer {
        id: statusCoalesceTimer
        interval: 16
        repeat: false
        onTriggered: root.requestStatus()
    }

    Timer {
        interval: 250
        running: root.listsBusy
        onTriggered: root.busyVisible = true
    }

    Timer {
        id: resizeSettleTimer
        interval: 150
        onTriggered: root.resizing = false
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
    Column {
        anchors.fill: parent

        StagedFileListSection {
            id: stagedSection
            width: parent.width
            height: wantsFillHeight ? root.fillHeight : implicitHeight
            animated: !root.resizing

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
                                root.runBulk("unstageAll",
                                             "All files unstaged successfully", "Unstage All",
                                             "Failed to unstage all files", "Unstage Error",
                                             "Unstaging all files")
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
            width: parent.width
            height: wantsFillHeight ? root.fillHeight : implicitHeight
            animated: !root.resizing

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
                                    root.runBulk("stageAll",
                                                 "All files staged successfully", "Stage All",
                                                 "Failed to stage all files", "Stage Error",
                                                 "Staging all files")
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
    }

    // Blocks the lists while they are stale, and shows the waiter once the wait is noticeable
    MouseArea {
        anchors.fill: parent
        enabled: root.listsBusy

        Loader {
            anchors.fill: parent
            active: root.busyVisible || opacity > 0
            opacity: root.busyVisible ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: Style.motionMedium
                    easing.type: Easing.OutCubic
                }
            }

            sourceComponent: BusyWaiter {
                // Keeps its text while fading out
                Binding on message {
                    value: root.busyText
                    when: root.listsBusy
                    restoreMode: Binding.RestoreNone
                }
            }
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
        const conflictedPaths = new Set()
        root.unstagedModel.forEach(file => {
            if (file.isConflicted) {
                conflictedPaths.add(file.path)
            }
        })

        let conflicted = paths.filter(path => conflictedPaths.has(path))
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

    function runBulk(method, successText, successTitle, failureText, failureTitle, busyText) {
        const repo = root.activeRepo
        if(!root.statusController || !repo || root.bulkJob) {
            return
        }

        root.bulkJobs = root.bulkJobs.concat([{ repo: repo, text: busyText, refreshing: false }])

        AsyncGit.call(root.statusController, method, [],
            function(res) {
                if(res && res.success) {
                    root.notificationController.success(successText, successTitle, 3000)
                } else {
                    root.notificationController.error((res && res.errorMessage) || failureText, failureTitle, 5000)
                }

                root.refreshAfterBulk(repo)
            },
            function(error) {
                // Another repository was opened meanwhile: this one reloads when it is opened again
                if(error === AsyncGit.STALE) {
                    root.endBulkJob(repo, false)
                    return
                }

                root.notificationController.error(failureText, failureTitle, 5000)
                root.refreshAfterBulk(repo)
            })
    }

    // The lists show the old state until the status is read again, which takes a while on large
    // change sets, so the job stays until that status has been applied.
    function refreshAfterBulk(repo) {
        root.bulkJobs.forEach(job => {
            if(job.repo === repo) {
                job.refreshing = true
            }
        })

        root.requestStatus()
    }

    // Ends the job of \a repo, or only if its result is already being read when \a refreshedOnly
    function endBulkJob(repo, refreshedOnly) {
        root.bulkJobs = root.bulkJobs.filter(job => job.repo !== repo || (refreshedOnly && !job.refreshing))
    }

    function requestStatus() {
        if (!root.statusController)
            return

        const repo  = root.activeRepo
        let   token = ++root.statusToken

        statusCoalesceTimer.stop()

        AsyncGit.call(root.statusController, "status", [false],
            function (res) {
                if (token === root.statusToken) {
                    root.showStatus(repo, res && res.success ? res.data : null)
                }
            },
            function () {
                root.showStatus(repo, null)
            })
    }

    // \a files is null when the status could not be read
    function showStatus(repo, files) {
        if (repo === root.activeRepo) {
            if (files) {
                root.applyStatus(files)
            } else if (root.loadedRepo !== repo) {
                // Nothing to show for this repository, and nothing of the previous one either
                root.unstagedModel = []
                root.stagedModel = []
            }

            root.loadedRepo = repo
        }

        root.endBulkJob(repo, true)
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
