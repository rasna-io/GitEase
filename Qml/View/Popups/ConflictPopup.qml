import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

import GitEase
import GitEase_Style
import GitEase_Style_Impl

import "qrc:/GitEase/Qml/Core/Scripts/ConflictPopupUtils.js" as ConflictUtils

/*! ***********************************************************************************************
 * ConflictPopup
 * ************************************************************************************************/

Window {
    id: root

    enum InteractiveAction {
        None,
        Continue,
        Skip,
        Abort
    }

    enum OperationType {
        None,
        Merge,
        Rebase,
        CherryPick
    }

    /* Property Declarations
     * ****************************************************************************************/
    property MergeController        mergeController         : null
    property RebaseController       rebaseController        : null
    property ConflictController     conflictController      : null
    property CherryPickController   cherryPickController    : null
    property StatusController       statusController        : null
    property CommitController       commitController        : null
    property NotificationController notificationController  : null
    property GuideController        guideController         : null

    property Item hostItem: null

    readonly property var hostWindow: root.hostItem ? root.hostItem.Window.window : null

    property var    conflicts       : []
    property var    selectedConflict: null
    property string selectedPath    : ""
    property var    modifiedFiles   : ({})
    property var    stagedFiles     : []

    //! path -> the file's contents as Git first reported them to this window, markers and all.
    property var    originalContent : ({})
    //! path -> how many conflicts that file had when this window first saw it.
    property var    originalConflictCounts : ({})
    property string headerText          : `${currentOperationName} Conflicts`
    property string applyingSubject     : ""
    property string commitHash          : ""
    property string ontoRef             : ""
    property string operationCommitHash : ""
    property int    modelRevision       : 0
    readonly property string shortCommitHash: root.commitHash.substring(0, 7)

    readonly property string positionText: {
        let total = root.conflicts.length + root.stagedFiles.length
        if (total === 0 || root.selectedPath === "")
            return ""

        let index = root.conflicts.findIndex(c => c.path === root.selectedPath)
        if (index < 0)
            return ""

        return `Conflict ${index + 1} of ${total}`
    }

    readonly property int openChunkCount: {
        root.modelRevision
        return root.selectedConflict?.blocks?.length ?? 0
    }

    readonly property int resolvedChunkCount: {
        root.modelRevision
        let count = 0
        for (let i = 0; i < conflictRows.count; ++i) {
            let row = conflictRows.get(i)
            if (row.type === "blockButton" && row.resolvedGroup > 0)
                count++
        }
        return count
    }

    readonly property int openConflictTotal: {
        root.modelRevision
        let total = 0
        for (let conflict of root.conflicts)
            total += conflict?.blocks?.length ?? 0
        return total
    }

    readonly property int conflictTotal: {
        let total = 0
        for (let path in root.originalConflictCounts)
            total += root.originalConflictCounts[path]
        return total
    }

    readonly property int resolvedConflictTotal:
        Math.max(0, root.conflictTotal - root.openConflictTotal)

    readonly property int totalChunkCount: root.openChunkCount + root.resolvedChunkCount

    readonly property bool canContinue: {
        return conflicts.length === 0
    }

    property int currentOperation: ConflictPopup.OperationType.None

    readonly property var currentController:{
        switch(currentOperation){
            case ConflictPopup.OperationType.Merge:
                return mergeController
            case ConflictPopup.OperationType.Rebase:
                return rebaseController
            case ConflictPopup.OperationType.CherryPick:
                return cherryPickController
            default:
                return null
        }
    }

    readonly property string currentOperationName:{
        switch(currentOperation){
            case ConflictPopup.OperationType.Merge:
                return "Merge"
            case ConflictPopup.OperationType.Rebase:
                return "Rebase"
            case ConflictPopup.OperationType.CherryPick:
                return "Cherry-pick"
            default:
                return ""
        }
    }

    property bool interactiveMode: false

    /* Signals
     * ****************************************************************************************/
    signal operationCompleted();
    signal interactiveActionRequested(int action)

    /* Object Properties
     * ****************************************************************************************/
    modality: Qt.ApplicationModal
    flags: Qt.Window | Qt.FramelessWindowHint
    color: "transparent"

    width: 1100
    height: 720

    onHostWindowChanged: {
        if (root.hostWindow && !root.visible)
            root.transientParent = root.hostWindow
    }

    onVisibleChanged: {
        if(!visible)
            return

        Qt.callLater(function() {
            let host = root.hostWindow
            if (host) {
                root.x = host.x + Math.round((host.width  - root.width)  / 2)
                root.y = host.y + Math.round((host.height - root.height) / 2)
            } else {
                root.x = Math.round((Screen.width  - root.width)  / 2)
                root.y = Math.round((Screen.height - root.height) / 2)
            }
        })

        if (!notificationController) {
            console.error("ConflictPopup: missing required controllers")
            close()
            return
        }

        if (!conflictController || !statusController) {
            notificationController.error("Cannot start conflict resolution: required Git controllers (conflict/status) are missing.",
                                         "Initialization Error", 4000)
            close()
            return
        }

        if (!currentController) {
            notificationController.error(`Cannot start ${currentOperationName.toLowerCase()} conflict resolution: the ${currentOperationName} controller is not available.`,
                                         "Initialization Error", 4000)
            close()
            return
        }

        root.clearFileCaches()
        selectedPath = ""
        refreshOperationContext()
        loadConflicts()
    }

    Component.onCompleted: {
        conflictWindowController.window = root
        conflictWindowController.setMinimumSize(940, 620)

        editorPane.scheduleMarkerUpdate()
    }

    ListModel {
        id: conflictRows
    }

    TextMetrics {
        id: widthCalculator
        font.family: Style.fontTypes.jetBrainsMono
        font.pixelSize: Style.appFont.captionPt
    }

    WindowController {
        id: conflictWindowController
    }

    Rectangle {
        anchors.fill: parent
        color: Style.colors.primaryBackground
        radius: 6
        clip: true
        border.color: Style.colors.primaryBorder
        border.width: 1

        /* Guide
         * ****************************************************************************************/
        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "conflict_resolution_tutorial"
            guideName: "Resolving Conflicts"
            guideIcon: Style.icons.warning
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return fileListComp },
                        icon: Style.icons.file,
                        title: "Conflicted Files",
                        description: "Files still carrying conflict markers are listed at the top, files you have already settled below them. Click one to open it on the right."
                    },
                    {
                        targetProvider: function() { return editorPane },
                        icon: Style.icons.penToSquare,
                        title: "Resolve a Conflict",
                        description: "Each conflict becomes a card showing both versions side by side. Keep ours, keep theirs, keep both, or edit the lines directly — the card turns green once it is settled."
                    },
                    {
                        targetProvider: function() { return toolbar },
                        icon: Style.icons.caretDown,
                        title: "Move Between Chunks",
                        description: "Jump straight to the next unresolved card instead of scrolling for it. The counter tells you how many are left in this file."
                    },
                    {
                        targetProvider: function() { return footer },
                        icon: Style.icons.check,
                        title: "Finish Up",
                        description: "The bars track how far you are through the files and their chunks. Continue once everything is resolved, skip this commit, or abort the whole operation."
                    }
                ]
            }
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.dp(3)
            spacing: 0

            ConflictHeader {
                id: header
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 10
                title: root.headerText
                applyingSubject: root.applyingSubject
                commitHash: root.shortCommitHash
                ontoRef: root.ontoRef
                positionText: root.positionText
                windowController: conflictWindowController
                onCloseRequested: root.requestAbort()
            }

            ConflictToolbar {
                id: toolbar
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                resolvedChunks: root.resolvedChunkCount
                totalChunks: root.totalChunkCount
                canNavigate: editorPane.canNavigate
                onPreviousChunkRequested: editorPane.goToPreviousChunk()
                onNextChunkRequested: editorPane.goToNextChunk()
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.primaryBorder
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                ConflictFileList {
                    id: fileListComp
                    conflictFiles: root.conflicts
                    currentPath: root.selectedPath
                    stagedFiles: root.stagedFiles
                    onFileSelected: (path) => root.selectFile(path)
                    onStageRequested: (path) => root.saveAndStage(path)
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Style.colors.primaryBorder
                }

                ConflictEditorPane {
                    id: editorPane
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    displayModel: conflictRows
                    selectedPath: root.selectedPath
                    selectedConflict: root.selectedConflict
                    revision: root.modelRevision

                    onAcceptBlockRequested: (blockIndex, mode) => root.acceptBlock(blockIndex, mode)
                    onResetRequested: root.resetSelectedFile()
                    onContentChanged: editorPane.scheduleMarkerUpdate()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.primaryBorder
            }

            ConflictFooter {
                id: footer
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                operationName: root.currentOperationName
                canContinue: root.canContinue
                canSkip: root.currentOperation !== ConflictPopup.OperationType.Merge
                resolvedFiles: root.stagedFiles.length
                totalFiles: root.conflicts.length + root.stagedFiles.length
                resolvedConflicts: root.resolvedConflictTotal
                totalConflicts: root.conflictTotal
                onAbortRequested: root.abortOperation()
                onSkipRequested: root.skipOperation()
                onContinueRequested: root.continueOperation()
            }
        }

        GuideOverlay {
            anchors.fill: parent
            z: 1000
            guideController: root.guideController
        }
    }

    Component {
        id: conflictConfirmationDialogComp
        ConflictConfirmationDialog { }
    }

    /* Functions
     * ****************************************************************************************/

    function loadConflicts(keepSelection = false) {
        if (!conflictController)
            return

        let res = conflictController.getConflicts()
        if (!res.success) {
            if (notificationController)
                notificationController.error(res.errorMessage, "Conflicts", 4000)
            return
        }

        let rawConflicts    = res.data || []
        let newStaged       = []
        let stagedPaths     = ({})

        root.captureOriginals(rawConflicts)

        let statusRes = statusController.status()
        if (statusRes.success) {
            for (let file of statusRes.data) {
                if (file.isStaged || file.isUntracked) {
                    stagedPaths[file.path] = true
                    newStaged.push({ path: file.path, status: labelFor(file) })
                }
            }
        }

        conflicts   = rawConflicts.filter(c => c && c.path && !stagedPaths[c.path])
        stagedFiles = newStaged

        if (conflicts.length === 0) {
            selectedConflict = null
            selectedPath = ""
            conflictRows.clear()
            root.modelRevision++
            return
        }

        let target = (keepSelection && selectedPath && conflicts.some(c => c.path === selectedPath))
                     ? selectedPath
                     : conflicts[0].path
        selectFile(target, true)
    }

    function refreshOperationContext() {
        root.commitHash      = ""
        root.applyingSubject = ""

        if (root.operationCommitHash !== "") {
            root.describeCommit(root.operationCommitHash)
            return
        }

        let statusRes = null

        switch (root.currentOperation) {
        case ConflictPopup.OperationType.Rebase:
            statusRes = root.rebaseController?.rebaseStatus()
            break

        case ConflictPopup.OperationType.CherryPick:
            statusRes = root.cherryPickController?.cherryPickStatus()
            break

        default:
            return
        }

        if (!statusRes || !statusRes.success || !statusRes.data)
            return

        root.describeCommit(statusRes.data.currentCommit || "")
    }

    function describeCommit(hash) {
        if (!hash)
            return

        root.commitHash = hash

        let commitRes = root.commitController?.getCommit(hash)
        if (commitRes && commitRes.success && commitRes.data)
            root.applyingSubject = commitRes.data.summary || ""
    }

    function captureOriginals(rawConflicts) {
        let baselines = Object.assign({}, root.originalContent)
        let counts = Object.assign({}, root.originalConflictCounts)
        let added = false

        for (let conflict of rawConflicts) {
            if (!conflict || !conflict.path || baselines[conflict.path] !== undefined)
                continue

            baselines[conflict.path] = (conflict.lines || []).join("\n")
            counts[conflict.path] = conflict.blocks?.length ?? 0
            added = true
        }

        if (added) {
            root.originalContent = baselines
            root.originalConflictCounts = counts
        }
    }

    function clearFileCaches() {
        root.modifiedFiles = ({})
        root.originalContent = ({})
        root.originalConflictCounts = ({})
    }

    function labelFor(file) {
        return file.indexStatus || "M"
    }

    function selectFile(path, forceRebuild = false) {
        if (selectedPath === path && !forceRebuild)
            return

        if (selectedPath && selectedPath !== path && conflictRows.count > 0) {
            let currentState = []
            for (let i = 0; i < conflictRows.count; ++i) {
                let row = conflictRows.get(i)

                currentState.push({
                    type: row.type,
                    text: row.text || "",
                    lineNumber: row.lineNumber || 0,
                    blockIndex: row.blockIndex !== undefined ? row.blockIndex : -1,
                    role: row.role || "",
                    cardNumber: row.cardNumber !== undefined ? row.cardNumber : 0,
                    resolvedGroup: row.resolvedGroup !== undefined ? row.resolvedGroup : -1,
                    resolvedMode: row.resolvedMode || ""
                })
            }
            let copy = Object.assign({}, modifiedFiles)
            copy[selectedPath] = currentState
            modifiedFiles = copy
        }

        if (stagedFiles.some(f => f.path === path)) {
            selectedConflict = null
            selectedPath = path

            let statusRes = statusController.getUnstagedDiffView(path)
            conflictRows.clear()
            if (statusRes && statusRes.success) {
                let liveContent = statusRes.data && statusRes.data.newText
                if (liveContent) {
                    let linesArray = liveContent.split('\n')
                    for (let i = 0; i < linesArray.length; ++i) {
                        conflictRows.append({
                            type: "contextLine",
                            text: linesArray[i],
                            lineNumber: i + 1
                        })
                    }
                }
            }

            root.modelRevision++
            editorPane.scheduleMarkerUpdate()
            return
        }

        for (let i = 0; i < conflicts.length; ++i) {
            if (conflicts[i].path === path) {
                selectedConflict = conflicts[i]
                selectedPath = path
                ConflictUtils.buildDisplayModel(
                    selectedConflict,
                    modifiedFiles,
                    selectedPath,
                    conflictRows,
                    editorPane.contentMetrics,
                    widthCalculator
                );
                break
            }
        }

        root.modelRevision++
        editorPane.scheduleMarkerUpdate()
    }

    function acceptBlock(blockIndex, mode) {
        if (!selectedPath || !selectedConflict)
            return

        let found = ConflictUtils.findBlockByIndex(selectedConflict.blocks, blockIndex)
        if (!found)
            return
        let block = found.block

        // Write current editor content and perform C++ resolution
        let currentContent = ConflictUtils.buildFullContent(conflictRows)
        conflictController.writeWorkingFile(selectedPath, currentContent)

        let res
        switch (mode) {
            case "ours":
                res = conflictController.acceptBlockOurs(selectedPath, blockIndex)
                break

            case "theirs":
                res = conflictController.acceptBlockTheirs(selectedPath, blockIndex)
                break

            case "both":
                res = conflictController.acceptBlockBoth(selectedPath, blockIndex)
                break

            default:
                return
        }
        if (!res.success) {
            notificationController.error(res.errorMessage, "Conflict Resolution", 4000)
            return
        }

        // Compute the text to keep
        let resolvedLines = ConflictUtils.computeResolvedLines(block, mode)

        // Update the ListModel in place
        ConflictUtils.replaceBlockInModel(conflictRows, blockIndex, block, resolvedLines, mode)

        // Update the cached block objects
        let lineDelta = resolvedLines.length - (block.endLine - block.startLine + 1)
        ConflictUtils.updateRemainingBlocks(selectedConflict, blockIndex, found.pos, lineDelta, block.endLine)

        // Keep the raw lines array in sync
        selectedConflict.lines = ConflictUtils.updateLinesArray(selectedConflict.lines, block, resolvedLines)

        let idx = conflicts.findIndex(c => c.path === selectedPath)
        if (idx >= 0) {
            let updated = conflicts.slice()
            updated[idx] = selectedConflict
            conflicts = updated
        }

        root.modelRevision++
        editorPane.scheduleMarkerUpdate()

        notificationController.success("Conflicts Resolved", "Conflict", 2000)
    }

    function saveAndStage(path) {
        if (!path)
            return

        let selectedConflict
        for (let i = 0; i < conflicts.length; ++i) {
            if (conflicts[i].path === path)
                selectedConflict = conflicts[i]
        }

        if (selectedConflict && selectedConflict.blocks && selectedConflict.blocks.length > 0) {
            showConflictStageWarning(path)
            return
        }

        performStage(path)
    }

    function showConflictStageWarning(path) {
        const d = conflictConfirmationDialogComp.createObject(root)

        d.title = "File Has Unresolved Conflicts"
        d.message = "This file still contains unresolved conflict markers.\n" +
                    "Stage it anyway?"

        d.saveTitle = "Save & Stage"
        d.saveDescription = "Save the file with conflicts and stage it"
        d.hasSave = true

        d.cancelTitle = "Cancel"
        d.cancelDescription = "Don't save The modification"

        d.hasAbort = false

        d.saved.connect(() => {
            performStage(path)
        })

        d.open()
    }

    function performStage(path) {
        if (!path)
            return

        let content = ConflictUtils.buildFullContent(conflictRows)

        let res = conflictController.writeWorkingFile(path, content)
        if (!res.success){
            notificationController.error(res.errorMessage || "Save failed", "Conflict", 4000)
            return
        }

        res = statusController.stageFile(path)
        if (!res.success){
            notificationController.error(res.errorMessage || "Stage failed", "Conflict", 4000)
            return
        }

        notificationController.success("File staged", "Conflict", 2500)

        loadConflicts(true)
    }

    function continueOperation() {
        if (interactiveMode) {
            interactiveActionRequested(ConflictPopup.InteractiveAction.Continue);
            return;
        }

        let res = currentController.continueOp()

        if (res.success) {
            notificationController.success(`${currentOperationName} completed`, currentOperationName, 2500)
            operationCompleted()
            close()
        }

        else {
            if (res.data && (res.data.status === "conflict" || res.data.hasConflicts)) {
                notificationController.warning("Continuing... but new conflicts found.", currentOperationName, 4000)

                // A different commit is being replayed now, so the header has to catch up too.
                root.clearFileCaches()
                refreshOperationContext()
                loadConflicts(true)
            }

            else {
                notificationController.error(res.errorMessage, currentOperationName, 4000)
            }
        }
    }

    function skipOperation() {
        if (interactiveMode) {
            interactiveActionRequested(ConflictPopup.InteractiveAction.Skip);
            return;
        }

        let res = currentController.skipOp()

        if (res.success) {
            notificationController.success("Commit skipped", currentOperationName, 2500)
            operationCompleted()
            close();
        }

        else {
            if (res.data && (res.data.status === "conflict" || res.data.hasConflicts)){
                notificationController.warning("Skipped, but new conflicts found in the next commit.", currentOperationName, 2500)

                root.clearFileCaches()
                refreshOperationContext()
                loadConflicts(true)
            }

            else{
                notificationController.error(res.errorMessage, currentOperationName, 4000)
            }
        }
    }

    function abortOperation() {
        if (interactiveMode) {
            interactiveActionRequested(ConflictPopup.InteractiveAction.Abort);
            return;
        }

        let res = currentController.abortOp()

        if (res.success)
            notificationController.success(`${currentOperationName} aborted`, currentOperationName, 2500)
        else
            notificationController.error(res.errorMessage, currentOperationName, 5000)

        root.clearFileCaches()
        conflictRows.clear()
        selectedPath = ""
        stagedFiles = []

        close()
    }

    function quitOperation() {
        let res = currentController.quitOp()

        if (res.success) {
            notificationController.success(`${currentOperationName} quitted`, currentOperationName, 2500)

            root.clearFileCaches()
            conflictRows.clear()
            selectedPath = ""
            stagedFiles = []

            close()
        }

        else {
            notificationController.error(res.errorMessage, currentOperationName, 4000)
        }
    }

    function saveAllModifications() {

        if (selectedPath) {
            let currentContent = ConflictUtils.buildFullContent(conflictRows);
            conflictController.writeWorkingFile(selectedPath, currentContent)
        }

        for (let path in modifiedFiles) {
            if (path === selectedPath)
                continue

            let lines = []
            let fileModel = modifiedFiles[path]
            for (let i = 0; i < fileModel.length; ++i) {
                let row = fileModel[i]
                if (row.type !== "blockButton") {
                    lines.push(row.text)
                }
            }
            let content = lines.join("\n")
            conflictController.writeWorkingFile(path, content)
        }

        if (notificationController)
            notificationController.success("All modifications saved locally", "Save", 2500)

        root.close()
    }

    function requestAbort() {
        let dialog = conflictConfirmationDialogComp.createObject(root)

        dialog.title = `Abort ${currentOperationName}?`
        dialog.message = "You have unresolved conflicts.\n" +
                         `Closing this window will abort the ${currentOperationName} and discard all progress.\n\n` +
                         "Are you sure you want to abort?"

        dialog.saved.connect(() => root.saveAllModifications())
        dialog.aborted.connect(() => root.abortOperation())
        dialog.open()
    }

    function resetSelectedFile() {
        if (!selectedPath || !conflictController)
            return

        let path     = root.selectedPath
        let original = root.originalContent[path]

        if (original === undefined) {
            if (notificationController)
                notificationController.warning("Nothing recorded to restore this file from.",
                                               "Conflict", 3000)
            return
        }

        let res = conflictController.writeWorkingFile(path, original)
        if (!res.success) {
            if (notificationController)
                notificationController.error(res.errorMessage || "Reset failed", "Conflict", 4000)
            return
        }

        let copy = Object.assign({}, modifiedFiles)
        delete copy[path]
        modifiedFiles = copy

        loadConflicts(true)

        if (notificationController)
            notificationController.info("File restored to its unresolved state", "Conflict", 2500)
    }
}
