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

    /* Property Declarations
     * ****************************************************************************************/
    property MergeController        mergeController         : null
    property RebaseController       rebaseController        : null
    property ConflictController     conflictController      : null
    property CherryPickController   cherryPickController    : null
    property StatusController       statusController        : null
    property NotificationController notificationController  : null

    property var    conflicts       : []
    property var    selectedConflict: null
    property string selectedPath    : ""
    property var    modifiedFiles   : ({})

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

    /* Signals
     * ****************************************************************************************/
    signal operationCompleted();

    /* Object Properties
     * ****************************************************************************************/
    width: 800
    height: 650

    modality: Qt.ApplicationModal
    color: "transparent"

    onVisibleChanged: {
        if(!visible)
            return

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
    }

    ListModel { id: displayModel }

    TextMetrics {
        id: widthCalculator
        font.family: Style.fontTypes.roboto
        font.pixelSize: 13
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
                    font.family: Style.fontTypes.roboto
                    font.bold: true
                    font.pixelSize: 14
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
                        ScrollBar.vertical: ScrollBar { active: true }

                        delegate: ConflictEditorDelegate {
                            width: conflictListView.width
                            horizontalOffset: conflictListView.horizontalScrollOffset
                            isCurrentItem: ListView.isCurrentItem

                            onSplitRequested        : (cursorPos)           => ConflictUtils.splitLine(displayModel, index, cursorPos, conflictListView)
                            onMergeUpRequested      : ()                    => ConflictUtils.mergeLineUp(displayModel, index, conflictListView)
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
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 11
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

        conflicts = res.data || []

        if (conflicts.length == 0){
            selectedConflict = null
            selectedPath = ""
            displayModel.clear()
            return
        }

        if (keepSelection && selectedPath) {
            let exists = conflicts.some(c => c.path === selectedPath)
            if (exists)
                selectFile(selectedPath, true)
            else
                selectFile(conflicts[0].path)
        } else {
            selectFile(conflicts[0].path)
        }
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

        // 2. Switch File
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
    }

    function acceptBlock(blockIndex, mode) {
        if (!selectedPath)
            return

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
                break
        }

        if (!res.success) {
            notificationController.error(res.errorMessage, "Conflict Resolution", 4000)
        }

        else {
            notificationController.success("Conflicts Resolved", "Conflict", 2500)

            // Clear memory state so fresh Git changes load
            let copy = Object.assign({}, modifiedFiles)
            delete copy[selectedPath]
            modifiedFiles = copy

            loadConflicts(true)
        }
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

        d.saveTitle = "Stage Anyway"
        d.saveDescription = "The modification will be saved"

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

        // Clear memory state since changes are successfully staged
        let copy = Object.assign({}, modifiedFiles)
        delete copy[path]
        modifiedFiles = copy

        loadConflicts(true)
    }

    function continueOperation() {
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
        let res = currentController.abortOp()

        if (res.success) {
            notificationController.success(`${currentOperationName} aborted`, currentOperationName, 2500)

            // WIPE CACHE AND VIEW
            modifiedFiles = ({})
            displayModel.clear()
            selectedPath = ""

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
}
