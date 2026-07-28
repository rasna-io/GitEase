import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * CommittingPage
 * Committing Page shown commit actions placeholder, file list placeholder and diff placeholder
 * ************************************************************************************************/

Page {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    pageId: "committing"
    title: "Committing"
    icon: Style.icons.gitBranch

    property AppModel                appModel:                null

    property RepositoryController    repositoryController:    null

    property StatusController        statusController:        null

    property BranchController        branchController:        null

    property CommitController        commitController:        null

    property RemoteController        remoteController:        null

    property UserProfileController   userProfileController:   null

    property StashController         stashController:        null

    property NotificationController  notificationController:  null

    property UserAuthenticationPopup userAuthenticationPopup: null
    
    property UiSessionPopups         uiSessionPopups:         null

    property var                     pluginController:        null

    property TerminalController      terminalController:      null

    property GuideController         guideController:         null

    // Remote actions (Pull / Push / Fetch) are owned by the shared RemoteOperationsSession so
    property RemoteOperationsSession remoteOperationsSession:              null
    property bool                    isFetching:             remoteOperationsSession ? remoteOperationsSession.isFetching : false
    property var                     activeFetchRemotes:     remoteOperationsSession ? remoteOperationsSession.activeFetchRemotes : []
    property var                     pendingFetchRemoteNames: remoteOperationsSession ? remoteOperationsSession.pendingFetchRemoteNames : []
    property var                     fetchBatchResults:      remoteOperationsSession ? remoteOperationsSession.fetchBatchResults : []
    property bool                    currentFileEdited: false

    property string                  selectedFilePath:        ""

    // Exposed to MainWindow's header area (see MainWindow.qml)
    headerContent: CommittingPageHeader {
        branchController: root.branchController
        notificationController: root.notificationController
        remoteController: root.remoteController
        guideController: root.guideController
    }

    onStatusControllerChanged: {
        branchController.getCurrentBranchName()
    }

    Component.onCompleted: {
        root.onPageChange = function(callback) {
            if (!root.currentFileEdited) {
                callback(true)
                return
            }
            var d = unsavedChangesDialogComp.createObject(root)
            d.title = "Unsaved Changes"
            d.message = "You have unsaved changes in: " + root.selectedFilePath
            d.saved.connect(() => {
                root.saveFile()
                callback(true)
            })
            d.aborted.connect(() => { callback(true) })
            d.cancelled.connect(() => { callback(false) })
            d.open()
        }
    }

    /* Children
     * ****************************************************************************************/

    Connections {
        target: repositoryController

        function onCurrentRepoChanged() {
            changesFileLists.updateStatus()
        }
    }

    CommitAmendPopup {
        id: amendPopup
        anchors.centerIn: parent

        commitController        : root.commitController
        notificationController  : root.notificationController
        changeCommitMessage     : !committingButton.commitEnabled

        onAmendSuccessful: {
            changesFileLists.updateStatus()
            commitTextArea.text = ""
        }
    }

    Connections {
        target: terminalController

        function onGitStateChanged() {
            root.showSaveDialog(
                        () => {
                            changesFileLists.updateStatus()
                        }
            )
        }
    }

    Connections {
        target: Qt.application
        
        function onStateChanged() {
            if (Qt.application.state === Qt.ApplicationActive) {
                changesFileLists.updateStatus()
            }
        }
    }



    RowLayout {
        anchors.fill: parent
        spacing: 8
        anchors.margins: 0
        spacing: 0

        // Left panel: two stacked placeholders
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 330
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                spacing: 8

                Rectangle {
                    id: commitPanel
                    Layout.fillWidth: true
                    Layout.preferredHeight: commitColumn.implicitHeight + 24
                    Layout.maximumHeight: 300
                    color: Style.colors.actionPillBg
                    radius: 5
                    border.width: 1
                    border.color: Style.colors.chipBorder

                    GuideHoverTrigger {
                        guideController: root.guideController
                        guideId: "commit_panel_tutorial"
                        guideName: "Commit Panel"
                        guideIcon: Style.icons.penToSquare
                        guidePage: "committing"
                        stepsFactory: function() {
                            return [
                                {
                                    targetProvider: function() { return commitTextArea },
                                    icon: Style.icons.penToSquare,
                                    title: "Commit Message",
                                    description: "Describe your change in the present tense — 'Fix login timeout' not 'Fixed login timeout'. Keep the summary under 72 characters."
                                },
                                {
                                    targetProvider: function() { return commitBtn },
                                    icon: Style.icons.arrowRight,
                                    title: "Commit",
                                    description: "Records every staged file as a permanent snapshot in history. Nothing leaves your machine — this is a local operation only.",
                                    commands: [{ command: "git commit -m \"…\"" }]
                                },
                                {
                                    targetProvider: function() { return caretBtn },
                                    icon: Style.icons.caretDown,
                                    title: "Commit Extras  ·  ▾ dropdown",
                                    description: "Commit & Push runs git commit then git push in one step. Commit Amend runs git commit --amend — rewrites the most recent local commit (message or content) instead of creating a new one."
                                },
                                {
                                    targetProvider: function() { return moreOptionsBtn },
                                    icon: Style.icons.arrowRight,
                                    title: "Remote Operations  ·  ⋮ menu",
                                    description: "Push uploads your local commits. Force Push rewrites the remote branch with your local history, but safely aborts if someone else pushed first. Fetch downloads remote changes without merging. Pull fetches and merges in one step.",
                                    commands: [
                                        { label: "Push",       command: "git push" },
                                        { label: "Force Push", command: "git push --force-with-lease" },
                                        { label: "Fetch",      command: "git fetch --all" },
                                        { label: "Pull",       command: "git pull" }
                                    ]
                                }
                            ]
                        }
                    }

                    ColumnLayout {
                        id: commitColumn
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 10

                        ContextMenu {
                            id: commitOptionsMenu
                            parent: commitPanel
                            menuModel: [
                                {
                                    text: "Push Force",
                                    icon: Style.icons.arrowUp,
                                    action: function() {
                                        root.pushAndUpdate(true)
                                    }
                                },
                                {
                                    text: "Fetch",
                                    icon: Style.icons.download,
                                    enabled: !root.isFetching,
                                    action: function() {
                                        root.fetch()
                                    }
                                },
                                {
                                    text: "Pull",
                                    icon: Style.icons.arrowDown,
                                    enabled: !root.isFetching,
                                    action: function() {
                                        root.pullAndUpdate()
                                    }
                                }
                            ]
                        }

                        ModernInputArea {
                            id: commitTextArea

                            Layout.fillWidth: true

                            placeholder: "What did you change?..."
                        }

                        RowLayout {
                            id: committingButton
                            Layout.fillWidth: true
                            spacing: 6

                            readonly property bool commitEnabled: changesFileLists.stagedModel.length > 0 && commitTextArea.text !== ""

                            Component.onCompleted: buildCommitMenu()

                            onCommitEnabledChanged: buildCommitMenu()

                            function buildCommitMenu() {
                                let items = []

                                items.push({
                                    text: commitEnabled ? "Commit Amend" : "Change commit message",
                                    icon: Style.icons.penToSquare,
                                    action: function() { amendPopup.open() }
                                })

                                if (commitEnabled) {
                                    items.push({
                                        text: "Commit && Push",
                                        icon: Style.icons.arrowUp,
                                        action: function() {
                                            if (!root.commitAndUpdate()) return
                                            root.pushAndUpdate()
                                        }
                                    })
                                }

                                commitDropMenu.menuModel = items
                            }

                            Rectangle {
                                id: commitBtn
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 5
                                color: committingButton.commitEnabled ? Style.colors.commitButton : Style.colors.disabledButton

                                Text {
                                    anchors.centerIn: parent
                                    text: "Commit"
                                    color: Style.colors.secondaryForeground
                                    font.family: Style.fontTypes.inter
                                    font.pixelSize: Style.appFont.mediumPt
                                    font.weight: Font.DemiBold
                                }

                                MouseArea {
                                    id: commitBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: committingButton.commitEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    enabled: committingButton.commitEnabled

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 5
                                        color: parent.containsMouse ? Qt.rgba(0,0,0,0.12) : "transparent"
                                    }

                                    onClicked: root.commitAndUpdate()
                                }
                            }

                            Rectangle {
                                id: caretBtn
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                radius: 5
                                color: Style.colors.commitButton

                                Text {
                                    anchors.centerIn: parent
                                    text: Style.icons.caretDown
                                    font.family: Style.fontTypes.font6ProSolid
                                    font.pixelSize: Style.appFont.defaultPt
                                    color: Style.colors.secondaryForeground
                                }

                                MouseArea {
                                    id: caretBtnMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 5
                                        color: parent.containsMouse ? Qt.rgba(0,0,0,0.12) : "transparent"
                                    }

                                    onClicked: {
                                        var pos = caretBtn.mapToItem(commitPanel, 0, caretBtn.height)
                                        commitDropMenu.x = Math.min(pos.x, commitPanel.width - commitDropMenu.implicitWidth - 48)
                                        commitDropMenu.y = pos.y + 4
                                        commitDropMenu.open()
                                    }
                                }

                                ContextMenu {
                                    id: commitDropMenu
                                    parent: commitPanel
                                }
                            }

                            Rectangle {
                                id: moreOptionsBtn
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                radius: 5
                                color: Style.colors.actionPillBg
                                border.color: Style.colors.chipBorder
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u22EE"
                                    font.pixelSize: Style.appFont.h2Pt
                                    color: commitOptionsDotMouse.containsMouse ? Style.colors.foreground : Style.colors.secondaryText
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }

                                MouseArea {
                                    id: commitOptionsDotMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        var pos = parent.mapToItem(commitPanel, 0, parent.height)
                                        commitOptionsMenu.x = Math.min(pos.x, commitPanel.width - commitOptionsMenu.implicitWidth - 12)
                                        commitOptionsMenu.y = pos.y + 4
                                        commitOptionsMenu.open()
                                    }
                                }
                            }
                        }

                        Label {
                            id: errorMessageLabel
                            Layout.fillWidth: true

                            visible: errorMessageLabel.text !== ""
                            color: Style.colors.error
                            font.family: Style.fontTypes.inter
                            font.pixelSize: Style.appFont.smallPt
                            wrapMode: TextEdit.Wrap
                        }
                    }
                }

                ChangesFileLists {
                    id: changesFileLists

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    guideController: root.guideController
                    statusController: root.statusController
                    notificationController: root.notificationController
                    stashController: root.stashController
                    currentFile: root.selectedFilePath
                    showSaveDialog: root.showSaveDialog

                    onFileSelected: function(filePath, isStaged) {
                        if (filePath === root.selectedFilePath)
                        {
                            root.selectedFilePath = filePath
                            root.updateDiff(isStaged)
                            return
                        }

                        root.showSaveDialog(
                                    () => {
                                        root.selectedFilePath = filePath
                                        root.updateDiff(isStaged)
                                    }
                        )
                    }

                    onChangesAborted: {
                        root.currentFileEdited = false
                    }
                }
            }
        }

        DiffView {
            id: diffView
            Layout.fillHeight: true
            Layout.fillWidth: true
            chunkMode: true
            hasHeaderMiddleComponent: true
            selectEnabled: false
            appModel: root.appModel
            contextLines: 0
            expandLines: 10
            selectedFileStatus: changesFileLists.currentFileStatus

            guideController: root.guideController
            currentRepositoryName: root.appModel.currentRepository.name || ""

            onRequestStage: function (start, end, type, rows) {
                root.showSaveDialog(
                            () => {
                                let res = root.statusController.stageSelectedLines(root.selectedFilePath, start, end, type)
                                if (res.success) {
                                    root.notificationController.success("Selected lines staged", "Stage", 2000)
                                } else {
                                    root.notificationController.error(res.errorMessage || "Failed to stage selected lines", "Stage Error", 5000)
                                }
                                changesFileLists.updateStatus()
                            }
                )
            }

            onRequestRevert: function (start, end, type) {
                root.showSaveDialog(
                            () => {
                                let res = root.statusController.revertSelectedLines(root.selectedFilePath, start, end, type)
                                if (res.success) {
                                    root.notificationController.success("Selected lines reverted", "Revert", 2000)
                                } else {
                                    root.notificationController.error(res.errorMessage || "Failed to revert selected lines", "Revert Error", 5000)
                                }
                                changesFileLists.updateStatus()
                            }
                )
            }

            onFileEdited: function (isEdited) {
                root.currentFileEdited = isEdited
            }

            onRequestStash: function (start, end, type) {
                let res = root.stashController.stashLines(root.selectedFilePath, start, end, type)
                if (res.success) {
                    root.notificationController.success("Selected lines stashed", "Stash", 2000)
                } else {
                    root.notificationController.error(res.errorMessage || "Failed to stash selected lines", "Stash Error", 5000)
                }
                changesFileLists.updateStatus()
            }
        }

        // Non-visual loader: fetches the plugin's colorizer QtObject
        Loader {
            id: colorizerLoader
            visible: false
            onLoaded: {
                diffView.textColorizer = item ? function(text) { return item.colorize(text) } : null
            }
            onSourceChanged: {
                if (source === "") diffView.textColorizer = null
            }
        }
    }

    Component {
        id: unsavedChangesDialogComp
        UnsavedChangesDialog { }
    }

    Shortcut {
        sequence: "Ctrl+S"
        context: Qt.ApplicationShortcut

        onActivated: {
            let res = root.statusController.saveFile(root.selectedFilePath, diffView.editedFileBuffer)

            if (res.success) {
                root.currentFileEdited = false
                root.notificationController.success("File saved successfully", "Save", 3000)
            } else {
                root.notificationController.error("Failed to save changes to the file", "Save Error", 5000)
            }

            changesFileLists.updateStatus()
        }
    }

    function fetch() {
        root.remoteOperationsSession?.fetch()
    }

    function commit(amend) : bool {
        amend = amend || false
        const pm = root.pluginController?.pluginManager
        if (pm && pm.hasWorkflowPluginsFor("pre-commit")) {
            root._pendingCommitAmend = amend
            pm.notifyWorkflowEvent("pre-commit", { message: commitTextArea.text, amend: amend })
            // actual commit is triggered from workflowConnections.onWorkflowEventResolved
            return false  // async — result determined by workflow resolution
        }
        return root._doCommit(amend)
    }

    property bool _pendingCommitAmend: false

    Connections {
        id: workflowConnections
        target: root.pluginController?.pluginManager ?? null
        function onWorkflowEventResolved(event, ctx, allowed) {
            if (event !== "pre-commit") return
            if (allowed) {
                root._doCommit(root._pendingCommitAmend)
            } else {
                root.notificationController.warning("Commit blocked by a plugin.", "Commit", 4000)
            }
        }
    }

    function _doCommit(amend) : bool {
        let res = commitController.commit(commitTextArea.text, amend, false)
        if (res.success) {
            commitTextArea.text = ""
            root.notificationController.success(`Commit ${amend ? "amended" : ""} successfully`, `Commit ${amend ? "Amend" : "" }`, 3000)
            root.pluginController?.pluginManager?.notifyWorkflowEvent("post-commit", { amend: amend })
        } else {
            root.notificationController.error(res.errorMessage || `Commit ${amend ? "Amend" : ""} failed`, `Commit ${amend ? "Amend" : ""} Error`, 5000)
            errorMessageLabel.text = res.errorMessage ?? `Commit ${amend ? "Amend" : ""} Error`
        }
        return res.success
    }

    function commitAndUpdate(amend) : bool {
        let result = root.commit(amend)
        changesFileLists.updateStatus()
        return result
    }

    function push(force) {
        root.remoteOperationsSession?.push(force)
    }

    function pushAndUpdate(force) {
        root.remoteOperationsSession?.pushAndUpdate(force)
    }

    function pull(secret) {
        root.remoteOperationsSession?.pull(secret)
    }

    function pullAndUpdate(secret) {
        root.remoteOperationsSession?.pullAndUpdate(secret)
        changesFileLists.updateStatus()
    }

    function updateDiff(isStaged) {
        // Load colorizer plugin for this file extension (or clear if none)
        const ext         = root.selectedFilePath.split('.').pop().toLowerCase()
        const colorizerUrl = root.pluginController?.pluginManager?.colorizerUrlFor(ext) ?? ""
        if (colorizerLoader.source !== colorizerUrl)
            colorizerLoader.source = colorizerUrl

        let oldY = diffView.scrollPosition

        let res = root.statusController.getChunkedDiffView(root.selectedFilePath, isStaged)
        if (res.success)
            diffView.chunkData = res.data.chunks
        res = root.statusController.getDiffView(root.selectedFilePath, isStaged)
        if (res.success)
            diffView.diffData = res.data.lines

        let fileRows = []
        for(var i =0;i<res.data.lines.length;i++)
        {
            let line = res.data.lines[i]
            let right   = (line.type === GitDiff.Deleted)   ? "" :
                          (line.type === GitDiff.Modified   ? line.newContent : line.content)
            fileRows.push(right)
        }

        diffView.selectedFile = root.selectedFilePath
        diffView.originalFileBuffer = fileRows.slice()
        diffView.editedFileBuffer = fileRows.slice()

        diffView.readOnly = isStaged

        Qt.callLater(() => { diffView.scrollPosition = oldY })
    }

    function showSaveDialog(nextAction) {
        if (!root.currentFileEdited) {
            nextAction()
            return
        }

        let d = unsavedChangesDialogComp.createObject(root)

        d.title = "Unsaved Changes"
        d.message = "You have unsaved changes in: " + root.selectedFilePath

        d.saved.connect(() => {
            root.saveFile()
            d.destroy()
            nextAction()
        })

        d.aborted.connect(() => {
            d.destroy()
            nextAction()
        })

        d.cancelled.connect(() => {
            d.destroy()
        })

        d.open()
    }

    function saveFile() {
        let res = root.statusController.saveFile(root.selectedFilePath, diffView.editedFileBuffer)

        if (res.success) {
            root.currentFileEdited = false
            root.notificationController.success("File saved successfully", "Save", 3000)
        } else {
            root.notificationController.error("Failed to save changes to the file", "Save Error", 5000)
        }
    }
}
