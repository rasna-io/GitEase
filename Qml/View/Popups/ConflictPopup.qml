import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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

    /* Property Declarations
     * ****************************************************************************************/
    property MergeController        mergeController         : null
    property RebaseController       rebaseController        : null
    property ConflictController     conflictController      : null
    property CherryPickController   cherryPickController    : null
    property StatusController       statusController        : null
    property NotificationController notificationController  : null
    property GuideController        guideController         : null

    property var    conflicts       : []
    property var    selectedConflict: null
    property string selectedPath    : ""
    property var    modifiedFiles   : ({})
    property var    stagedFiles     : []

    property string headerText          : `${currentOperationName} Conflicts`
    property string continueButtonText  : `Continue ${currentOperationName}`

    readonly property bool canContinue: {
        return conflicts.length === 0
    }

    enum OperationType {
        None,
        Merge,
        Rebase,
        CherryPick
    }
    property int currentOperation: ConflictPopup.OperationType.None

    readonly property var currentController:{
        switch(currentOperation){
            case ConflictPopup.OperationType.Merge      : return mergeController
            case ConflictPopup.OperationType.Rebase     : return rebaseController
            case ConflictPopup.OperationType.CherryPick : return cherryPickController
            default                                     : return null
        }
    }
    readonly property string currentOperationName:{
        switch(currentOperation){
            case ConflictPopup.OperationType.Merge      : return "Merge"
            case ConflictPopup.OperationType.Rebase     : return "Rebase"
            case ConflictPopup.OperationType.CherryPick : return "Cherry-pick"
            default                                     : return ""
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
    color: "transparent"

    width: 800
    height: 650

    onWidthChanged: {
        if (visible && width != 800)
            width = 800
    }
    onHeightChanged: {
        if (visible && height != 650)
            height = 650
    }

    onVisibleChanged: {
        if(!visible)
            return

        Qt.callLater(function() {
            x = (Screen.width - width) / 2
            y = (Screen.height - height) / 2
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

        modifiedFiles = ({})
        selectedPath = ""
        loadConflicts()
    }

    Component.onCompleted: {
        windowController.window = root
        windowController.setMinimumSize(width, height)

        markersUpdateTimer.start()
    }

    ListModel { id: displayModel }

    TextMetrics {
        id: widthCalculator
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.h3Pt
    }

    WindowController {
        id: windowController
    }

    Rectangle {
        anchors.fill: parent
        color: Style.colors.primaryBackground
        radius: 5
        clip: true
        border.color: Style.colors.accent
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
                        description: "Every file with unresolved conflicts is listed here. Click one to open it in the editor on the right; the checkmark stages a file once you're happy with it."
                    },
                    {
                        targetProvider: function() { return conflictListView },
                        icon: Style.icons.penToSquare,
                        title: "Resolve a Conflict",
                        description: "Each conflicting block shows both versions. Accept ours, theirs, or both, or edit the text directly like a normal editor."
                    },
                    {
                        targetProvider: function() { return continueBtn },
                        icon: Style.icons.check,
                        title: "Continue",
                        description: "Once every file is resolved and staged, click here to continue the operation. Skip moves past this commit, and the close button lets you abort entirely."
                    }
                ]
            }
        }

        ColumnLayout {
            spacing: 8
            anchors.fill: parent
            anchors.margins: 20

            // Header
            RowLayout {
                Layout.fillWidth: true

                Text {
                    text: root.headerText
                    color: Style.colors.secondaryText
                    font.family: Style.fontTypes.inter
                    font.bold: true
                    font.pixelSize: Style.appFont.largePt
                }

                MouseArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 27
                    Layout.leftMargin: 20
                    Layout.rightMargin: 20
                    cursorShape: Qt.SizeAllCursor

                    property point clickPos

                    onPressed: function(mouse) {
                        clickPos = Qt.point(mouse.x, mouse.y)
                    }

                    onPositionChanged: function(mouse) {
                        root.x += mouse.x - clickPos.x
                        root.y += mouse.y - clickPos.y
                    }
                }

                WindowsButton {
                    id: minimizeButton
                    onClicked: windowController.minimize()
                    Material.accent: Style.colors.windowsMinimize
                    content: Rectangle {
                        anchors.centerIn: parent
                        width: 10
                        height: 2
                        radius: 1
                        color: minimizeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                    }
                }

                // Close Button
                WindowsButton {
                    id: closeButton
                    Material.accent: Style.colors.windowsClose
                    content: Item {
                        anchors.centerIn: parent
                        width: 10; height: 10
                        Rectangle {
                            width: 12; height: 2; radius: 1
                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                            anchors.centerIn: parent; rotation: 45
                        }
                        Rectangle {
                            width: 12; height: 2; radius: 1
                            color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                            anchors.centerIn: parent; rotation: -45
                        }
                    }
                    onClicked: {
                        var d = conflictConfirmationDialogComp.createObject(root)
                        d.title = `Abort ${currentOperationName}?`
                        d.message = "You have unresolved conflicts.\n" +
                                    `Closing this window will abort the ${currentOperationName} and discard all progress.\n\n` +
                                    "Are you sure you want to abort?"
                        d.saved.connect(() => { root.saveAllModifications() })
                        d.aborted.connect(() => { root.abortOperation() })
                        d.open()
                    }
                }
            }

            // Content
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                // Left panel: file list
                ConflictFileList {
                    id: fileListComp
                    conflictFiles: root.conflicts
                    currentPath: root.selectedPath
                    stagedFiles: root.stagedFiles
                    onFileSelected  : (path) => root.selectFile(path)
                    onStageRequested: (path) => root.saveAndStage(path)
                }

                // Right panel: conflict editor
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Style.colors.editorBackgroound
                    border.width: 1
                    border.color: Style.colors.primaryBorder
                    radius: 4

                    ListView {
                        id: conflictListView
                        property real horizontalScrollOffset: 0
                        property real maxContentWidth: 0

                        anchors.fill: parent
                        clip: true
                        model: displayModel

                        cacheBuffer: 5000
                        reuseItems: true
                        anchors.bottomMargin: hScrollBar.visible ? hScrollBar.height : 0
                        ScrollBar.vertical: ScrollBar {
                            id: vScrollBar
                            active: true
                        }

                        Item {
                            id: conflictMarkerOverlay
                            parent: conflictListView
                            x: vScrollBar.x
                            y: vScrollBar.y
                            width: vScrollBar.width
                            height: vScrollBar.height
                            z: 100
                            clip: true

                            Repeater {
                                model: conflictMarkersModel
                                delegate: Rectangle {
                                    x: 0
                                    y: model.y * conflictMarkerOverlay.height
                                    width: conflictMarkerOverlay.width
                                    height: Math.max(2, model.height * conflictMarkerOverlay.height)
                                    color: Style.colors.conflictMarker
                                    opacity: 0.85
                                }
                            }

                            Timer {
                                id: markersUpdateTimer
                                interval: 50
                                repeat: false
                                onTriggered: root.updateConflictMarkers()
                            }

                            onHeightChanged: {
                                if (height > 0)
                                    markersUpdateTimer.restart()
                            }
                        }

                        delegate: ConflictEditorDelegate {
                            width: conflictListView.width
                            horizontalOffset: conflictListView.horizontalScrollOffset
                            isCurrentItem: ListView.isCurrentItem

                            onSplitRequested: (cursorPos) => {
                                ConflictUtils.splitLine(displayModel, index, cursorPos, conflictListView)
                                root.updateConflictMarkers()
                            }
                            onMergeUpRequested: () => {
                                ConflictUtils.mergeLineUp(displayModel, index, conflictListView)
                                root.updateConflictMarkers()
                            }
                            onAcceptBlockRequested  : (blockIndex, mode)    => root.acceptBlock(blockIndex, mode)
                            onMoveFocusUp           : conflictListView.currentIndex = Math.max(0, index - 1)
                            onMoveFocusDown         : conflictListView.currentIndex = Math.min(displayModel.count - 1, index + 1)
                        }
                    }

                    ScrollBar {
                        id: hScrollBar
                        orientation: Qt.Horizontal
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        size: conflictListView.maxContentWidth === 0 ? 1 : (conflictListView.width * 0.5) / conflictListView.maxContentWidth
                        active: true
                        visible: size < 1.0

                        onPositionChanged: {
                            conflictListView.horizontalScrollOffset = position * conflictListView.maxContentWidth
                        }
                    }

                    EmptyStateView {
                        anchors.fill: parent
                        visible: displayModel.count === 0
                        title: "No Conflicted files to show"
                        details: "All conflicts have been resolved."
                    }
                }
            }

            // Footer buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }

                Button {
                    flat: true
                    text: "Skip"
                    visible: currentOperation !== ConflictPopup.OperationType.Merge
                    Material.foreground: hovered ? Style.colors.secondaryForeground : Style.colors.foreground
                    background: Rectangle {
                        color: parent.hovered ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                    }
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: skipOperation()
                    }
                }

                Button {
                    id: continueBtn
                    flat: true
                    text: root.continueButtonText

                    Material.foreground: root.canContinue && mouse.containsMouse ? Style.colors.secondaryForeground : Style.colors.foreground

                    background: Rectangle {
                        color: root.canContinue && mouse.containsMouse ? Style.colors.accent : Style.colors.secondaryBackground
                        border.color: Style.colors.accent
                        radius: 5
                        opacity: root.canContinue ? 1.0 : 0.5
                    }

                    ToolTip {
                        id: tip
                        parent: continueBtn
                        visible: mouse.containsMouse
                        delay: 100
                        timeout: 2000
                        text: root.canContinue ? "Click to continue" : "Resolve all files to continue"
                        x: (continueBtn.width - width) / 2
                        y: -height - 6
                        padding: 6
                        contentItem: Text {
                            text: tip.text
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.defaultPt
                            color: "#ffffff"
                        }
                        background: Rectangle {
                            radius: 6
                            color: Qt.rgba(0, 0, 0, 0.85)
                            border.color: Qt.rgba(1, 1, 1, 0.12)
                            border.width: 1
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: root.canContinue ? Qt.PointingHandCursor : Qt.ForbiddenCursor
                        onClicked: {
                            if (root.canContinue)
                                continueOperation()
                        }
                    }
                }
            }
        }

        // ConflictPopup is its own top-level Window, so the shared GuideOverlay embedded in
        // MainWindow can't reach into it — this instance renders the spotlight/tooltip locally.
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

    ListModel { id: conflictMarkersModel }

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
            displayModel.clear()
            return
        }

        let target = (keepSelection && selectedPath && conflicts.some(c => c.path === selectedPath))
                     ? selectedPath
                     : conflicts[0].path
        selectFile(target, true)
    }

    function labelFor(file) {
        return file.indexStatus || "M"
    }

    function selectFile(path, forceRebuild = false) {
        if (selectedPath === path && !forceRebuild)
            return

        // 1. Save current displayModel state before switching
        if (selectedPath && selectedPath !== path && displayModel.count > 0) {
            let currentState = []
            for (let i = 0; i < displayModel.count; ++i) {
                let row = displayModel.get(i)
                currentState.push({
                    type: row.type,
                    text: row.text || "",
                    lineNumber: row.lineNumber || 0,
                    blockIndex: row.blockIndex !== undefined ? row.blockIndex : -1,
                    role: row.role || ""
                })
            }
            let copy = Object.assign({}, modifiedFiles)
            copy[selectedPath] = currentState
            modifiedFiles = copy
        }

        // 2. If it's a staged file, show its current file content
        if (stagedFiles.some(f => f.path === path)) {
            selectedConflict = null
            selectedPath = path

            // fetch current working directory content
            let statusRes = statusController.getUnstagedDiffView(path)
            displayModel.clear()
            if (statusRes && statusRes.success) {
                let liveContent = statusRes.data && statusRes.data.newText
                if (liveContent) {
                    let linesArray = liveContent.split('\n')
                    for (let i = 0; i < linesArray.length; ++i) {
                        displayModel.append({
                            type: "contextLine",
                            text: linesArray[i],
                            lineNumber: i + 1
                        })
                    }
                }
            }
            return
        }

        // 3. Otherwise, switch to the conflict file and build its display model
        for (let i = 0; i < conflicts.length; ++i) {
            if (conflicts[i].path === path) {
                selectedConflict = conflicts[i]
                selectedPath = path
                ConflictUtils.buildDisplayModel(
                    selectedConflict,
                    modifiedFiles,
                    selectedPath,
                    displayModel,
                    conflictListView,
                    widthCalculator
                );
                break
            }
        }

        Qt.callLater(function() {
            if (conflictMarkerOverlay) root.updateConflictMarkers();
        });
    }

    function acceptBlock(blockIndex, mode) {
        if (!selectedPath || !selectedConflict)
            return

        let found = ConflictUtils.findBlockByIndex(selectedConflict.blocks, blockIndex)
        if (!found)
            return
        let block = found.block

        // Write current editor content and perform C++ resolution
        let currentContent = ConflictUtils.buildFullContent(displayModel)
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
        ConflictUtils.replaceBlockInModel(displayModel, blockIndex, block, resolvedLines)

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

        // Rebuilt the conflict‑zone indicators
        Qt.callLater(updateConflictMarkers)

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

        let content = ConflictUtils.buildFullContent(displayModel)

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

                modifiedFiles = ({})
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

                modifiedFiles = ({})
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

        if (res.success) {
            notificationController.success(`${currentOperationName} aborted`, currentOperationName, 2500)

            // WIPE CACHE AND VIEW
            modifiedFiles = ({})
            displayModel.clear()
            selectedPath = ""
            stagedFiles = []

            close()
        }

        else {
            notificationController.error(res.errorMessage, currentOperationName, 4000)
        }
    }

    function quitOperation() {
        let res = currentController.quitOp()

        if (res.success) {
            notificationController.success(`${currentOperationName} quitted`, currentOperationName, 2500)

            // WIPE CACHE AND VIEW
            modifiedFiles = ({})
            displayModel.clear()
            selectedPath = ""
            stagedFiles = []

            close()
        }

        else {
            notificationController.error(res.errorMessage, currentOperationName, 4000)
        }
    }

    function saveAllModifications() {

        // 1. Save the currently active file on screen
        if (selectedPath) {
            let currentContent = ConflictUtils.buildFullContent(displayModel);
            conflictController.writeWorkingFile(selectedPath, currentContent)
        }

        // 2. Save any other files cached in memory
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

    function updateConflictMarkers() {
        conflictMarkersModel.clear()

        var totalRows = displayModel.count
        if (totalRows === 0 || conflictMarkerOverlay.height <= 0)
            return

        var blocks  = []
        var stack   = []
        for (var i = 0; i < displayModel.count; i++) {
            var row = displayModel.get(i)

            if (row.role === "marker-start") {
                stack.push(i)
            } else if (row.role === "marker-end" && stack.length > 0) {
                var startIdx = stack.pop()
                blocks.push({ startIdx: startIdx, endIdx: i })
            }
        }

        for (var b of blocks) {
            var yNorm = b.startIdx / totalRows
            var hNorm = (b.endIdx - b.startIdx + 1) / totalRows
            conflictMarkersModel.append({ y: yNorm, height: hNorm })
        }
    }
}
