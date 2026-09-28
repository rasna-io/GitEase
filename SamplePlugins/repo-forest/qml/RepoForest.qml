import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import GitEaseRepoForest

import "qrc:/GitEase/Qml/Core/Scripts/AsyncGit.js" as AsyncGit

/*! ***********************************************************************************************
 * RepoForest
 * Finds every repository under rootPath and fetches / pulls all (or the selected) ones.
 *
 * Operations run one at a time through AsyncGit on the Git worker threads, so the UI stays
 * responsive. HTTPS remotes are tried without a token first; a token is only requested when a
 * remote actually rejects the anonymous request.
 * ************************************************************************************************/

Rectangle {
    id: root

    enum QueueState {
        Ready,
        Running,
        Pause,
        PauseRequested,
        Stop
    }

    /* Property Declarations
     * ****************************************************************************************/
    property   RepositoryController         repositoryController
    property   BranchController             branchController
    property   RemoteController             remoteController
    property   UserAuthenticationPopup      userAuthenticationPopup
    property   string                       rootPath
    property   GitScanner                   gitScanner
    property   GuideController              guideController:          null

    property   var                          selectedIndexes:          []
    property   var                          operationQueue:           []
    property   int                          queueState:               RepoForest.QueueState.Ready
    property   bool                         isOpening:                false
    property   var                          operationLogs:            []

    //! "" = not asked yet, "skip" = declined, anything else = the token.
    property   string                       pat:                      ""

    readonly property int  repoCount:       reposModel.count
    readonly property bool allSelected:     repoCount > 0 && selectedIndexes.length === repoCount
    readonly property bool noneSelected:    selectedIndexes.length === 0
    readonly property bool someSelected:    !allSelected && !noneSelected
    readonly property int  selectedCount:   selectedIndexes.length
    readonly property bool isIdle:          queueState === RepoForest.QueueState.Ready

    //! Counters over the repositories touched in this session.
    property int touchedCount:  0
    property int finishedCount: 0
    property int failedCount:   0
    readonly property int progressPercent: touchedCount > 0 ? Math.round(finishedCount / touchedCount * 100) : 0

    /* Private Properties
     * ****************************************************************************************/
    //! The operation currently running: { operation, index, remotes, remoteIndex, failures }.
    property var    _job:           null
    //! Operations parked until the user provides a token: [{ operation, index }].
    property var    _authWaiting:   []
    property bool   _awaitingAuth:  false
    property var    _repoHandles:   []
    property var    _repoRemotes:   []

    /* Signals
    * ****************************************************************************************/
    signal closeRequested()

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground
    radius: 12
    clip: true
    border.color: Style.colors.primaryBorder
    border.width: 1

    onVisibleChanged: {
        if (visible) {
            root.reset()
            gitScanner.scan(root.rootPath)
        }
    }

    /* Functions
    * ****************************************************************************************/
    function reset() {
        reposModel.clear()
        root._repoHandles = []
        root._repoRemotes = []
        root.selectedIndexes = []
        root.operationQueue = []
        root.queueState = RepoForest.QueueState.Ready
        root.operationLogs = []
        root.pat = ""
        root._job = null
        root._authWaiting = []
        root._awaitingAuth = false
        root.touchedCount = 0
        root.finishedCount = 0
        root.failedCount = 0
    }

    //! Visual family of a status, used for its color.
    function kindOf(status) {
        switch (status) {
        case "Queued":       return "queued"
        case "Fetching":     return "fetching"
        case "Pulling":      return "pulling"
        case "Fetched":
        case "Up to date":
        case "Updated":      return "done"
        case "Local changes":
        case "Diverged":
        case "No upstream":  return "warning"
        case "Needs token":  return "auth"
        case "Failed":       return "error"
        case "Skipped":
        case "Stopped":      return "muted"
        default:             return "idle"
        }
    }

    function isFinishedKind(kind) {
        return kind === "done" || kind === "warning" || kind === "error" || kind === "muted"
    }

    function recountProgress() {
        let touched = 0, finished = 0, failed = 0
        for (let i = 0; i < reposModel.count; i++) {
            const kind = root.kindOf(reposModel.get(i).status)
            if (kind === "idle")
                continue
            touched++
            if (root.isFinishedKind(kind))
                finished++
            if (kind === "error" || kind === "warning")
                failed++
        }
        root.touchedCount = touched
        root.finishedCount = finished
        root.failedCount = failed
    }

    function setStatus(index, status, detail) {
        if (index < 0 || index >= reposModel.count)
            return
        reposModel.setProperty(index, "status", status)
        reposModel.setProperty(index, "detail", detail || "")
        if (status !== "Fetching" && status !== "Pulling")
            reposModel.setProperty(index, "progress", -1)
        root.recountProgress()

        if (autoScrollCheckBox.checked && (status === "Fetching" || status === "Pulling"))
            repoListView.positionViewAtIndex(index, ListView.Contain)
    }

    function logOperation(index, remoteName, operation, status, message) {
        const entry = {
            repoName:   index >= 0 && index < reposModel.count ? reposModel.get(index).name : "",
            remoteName: remoteName || "",
            operation:  operation,
            status:     status,
            message:    message,
            timestamp:  new Date().toLocaleTimeString(Qt.locale(), "hh:mm:ss")
        }
        root.operationLogs = root.operationLogs.concat([entry])
    }

    function toggleSelection(index) {
        let arr = root.selectedIndexes.slice()
        const pos = arr.indexOf(index)
        if (pos === -1)
            arr.push(index)
        else
            arr.splice(pos, 1)
        root.selectedIndexes = arr
    }

    function toggleSelectAll() {
        root.selectedIndexes = root.allSelected ? []
                                                : Array.from({ length: reposModel.count }, (_, i) => i)
    }

    function isQueuedOrRunning(index) {
        if (root._job && root._job.index === index)
            return true
        return root.operationQueue.some(op => op.index === index)
    }

    function enqueue(operation, index) {
        if (root.isQueuedOrRunning(index))
            return

        root.operationQueue = root.operationQueue.concat([{ operation: operation, index: index }])
        root.setStatus(index, "Queued")

        if (root.queueState === RepoForest.QueueState.Ready)
            root.processNext()
    }

    function enqueueSelected(operation) {
        root.selectedIndexes.slice().sort((a, b) => a - b).forEach(index => root.enqueue(operation, index))
    }

    function processNext() {
        root._job = null

        if (root.queueState === RepoForest.QueueState.Stop) {
            root.queueState = RepoForest.QueueState.Ready
            return
        }

        if (root.queueState === RepoForest.QueueState.PauseRequested) {
            root.queueState = RepoForest.QueueState.Pause
            return
        }

        if (root.queueState === RepoForest.QueueState.Pause)
            return

        if (root.operationQueue.length === 0) {
            root.queueState = RepoForest.QueueState.Ready
            return
        }

        root.queueState = RepoForest.QueueState.Running
        const next = root.operationQueue[0]
        root.operationQueue = root.operationQueue.slice(1)

        if (next.operation === "fetch")
            root.startFetch(next.index)
        else
            root.startPull(next.index)
    }

    function pauseQueue() {
        root.queueState = root._job ? RepoForest.QueueState.PauseRequested : RepoForest.QueueState.Pause
        root.logOperation(-1, "", "queue", "Info", "Queue paused")
    }

    function resumeQueue() {
        if (root.queueState !== RepoForest.QueueState.Pause && root.queueState !== RepoForest.QueueState.PauseRequested)
            return
        root.logOperation(-1, "", "queue", "Info", "Queue resumed")
        const wasRunning = root._job !== null
        root.queueState = wasRunning ? RepoForest.QueueState.Running : RepoForest.QueueState.Ready
        if (!wasRunning)
            root.processNext()
    }

    //! Drops everything still queued. The operation in flight cannot be interrupted and finishes normally.
    function stopQueue() {
        root.operationQueue.forEach(op => root.setStatus(op.index, "Stopped", "Removed from the queue"))
        root.operationQueue = []
        root.logOperation(-1, "", "queue", "Info", "Queue stopped")
        root.queueState = root._job ? RepoForest.QueueState.Stop : RepoForest.QueueState.Ready
    }

    function isSsh(url) {
        return root.repositoryController.detectGitProtocol(url) === RepositoryController.GitProtocol.SSH
    }

    function isAuthError(message) {
        return /auth|credential|401|403|replays|no callback set/i.test(message || "")
    }

    function tokenFor(url) {
        return root.isSsh(url) || root.pat === "skip" ? "" : root.pat
    }

    //! Parks an operation until a token is available. Returns true when it was parked.
    function parkForToken(operation, index, url) {
        if (root.isSsh(url) || root.pat !== "")
            return false

        root._authWaiting = root._authWaiting.concat([{ operation: operation, index: index }])
        root.setStatus(index, "Needs token", "This remote requires a personal access token")

        if (!root._awaitingAuth && root.userAuthenticationPopup) {
            root._awaitingAuth = true
            if (typeof root.userAuthenticationPopup.request === "function")
                root.userAuthenticationPopup.request(operation, reposModel.get(index).name, url)
            else
                root.userAuthenticationPopup.open()
        }
        return true
    }

    // ── Fetch ────────────────────────────────────────────────────────────────────────────────
    function startFetch(index) {
        const remotes = root._repoRemotes[index] || []
        if (!root._repoHandles[index]) {
            root.setStatus(index, "Failed", "Repository could not be opened")
            root.processNext()
            return
        }
        if (remotes.length === 0) {
            root.setStatus(index, "Skipped", "No remotes configured")
            root.logOperation(index, "", "fetch", "Skipped", "No remotes configured")
            root.processNext()
            return
        }

        root._job = { operation: "fetch", index: index, remotes: remotes, remoteIndex: 0, failures: [] }
        root.setStatus(index, "Fetching")
        root.fetchNextRemote()
    }

    function fetchNextRemote() {
        const job = root._job
        if (job.remoteIndex >= job.remotes.length) {
            root.finishFetch()
            return
        }

        const remote = job.remotes[job.remoteIndex++]
        job.currentRemote = remote
        worker.currentRepo = root._repoHandles[job.index]

        const ssh = root.isSsh(remote.url)
        const method = ssh ? "fetch" : "fetchWithToken"
        const args = ssh ? [remote.name] : [remote.name, root.tokenFor(remote.url)]

        AsyncGit.call(worker, method, args,
            result => root.onFetchResult(job, remote, result),
            error => root.onFetchResult(job, remote, { success: false, errorMessage: error }))
    }

    function onFetchResult(job, remote, result) {
        if (root._job !== job)
            return

        if (result && result.success) {
            root.logOperation(job.index, remote.name, "fetch", "Success", "Fetched")
            root.fetchNextRemote()
            return
        }

        const message = (result && result.errorMessage) || "Fetch failed"
        if (root.isAuthError(message) && root.parkForToken("fetch", job.index, remote.url)) {
            root.logOperation(job.index, remote.name, "fetch", "Info", "Waiting for a token")
            root.processNext()
            return
        }

        job.failures.push(remote.name + ": " + message)
        root.logOperation(job.index, remote.name, "fetch", "Failed", message)
        root.fetchNextRemote()
    }

    function finishFetch() {
        const job = root._job
        if (job.failures.length === 0)
            root.setStatus(job.index, "Fetched",
                           job.remotes.length === 1 ? "From " + job.remotes[0].name
                                                    : job.remotes.length + " remotes fetched")
        else
            root.setStatus(job.index, "Failed", job.failures.join(" · "))
        root.processNext()
    }

    // ── Pull ─────────────────────────────────────────────────────────────────────────────────
    //! The remote the current branch tracks, falling back to origin or the only remote.
    function pullRemoteFor(index) {
        const remotes = root._repoRemotes[index] || []
        const branch = reposModel.get(index).branchName

        worker.currentRepo = root._repoHandles[index]
        const upstream = worker.getUpstreamName(branch)
        if (upstream.success && upstream.data) {
            const upstreamRemote = remotes.find(r => upstream.data.startsWith(r.name + "/"))
            if (upstreamRemote)
                return upstreamRemote
        }
        return remotes.find(r => r.name === "origin") || (remotes.length === 1 ? remotes[0] : null)
    }

    function startPull(index) {
        if (!root._repoHandles[index]) {
            root.setStatus(index, "Failed", "Repository could not be opened")
            root.processNext()
            return
        }
        if ((root._repoRemotes[index] || []).length === 0) {
            root.setStatus(index, "Skipped", "No remotes configured")
            root.processNext()
            return
        }

        const remote = root.pullRemoteFor(index)
        if (!remote) {
            root.setStatus(index, "No upstream", "Set an upstream branch to choose which remote to pull from")
            root.logOperation(index, "", "pull", "Skipped", "No upstream remote")
            root.processNext()
            return
        }

        const job = { operation: "pull", index: index, currentRemote: remote }
        root._job = job
        root.setStatus(index, "Pulling", "From " + remote.name)

        const ssh = root.isSsh(remote.url)
        const args = ssh ? [remote.name, ""] : [remote.name, "", root.tokenFor(remote.url)]

        AsyncGit.call(worker, "pull", args,
            result => root.onPullResult(job, remote, result),
            error => root.onPullResult(job, remote, { success: false, errorMessage: error }))
    }

    function onPullResult(job, remote, result) {
        if (root._job !== job)
            return

        if (result && result.success) {
            const upToDate = result.data && result.data.status === "Already up to date"
            root.setStatus(job.index, upToDate ? "Up to date" : "Updated", "From " + remote.name)
            root.logOperation(job.index, remote.name, "pull", "Success", upToDate ? "Already up to date" : "Fast-forwarded")
            root.processNext()
            return
        }

        const message = (result && result.errorMessage) || "Pull failed"

        if (root.isAuthError(message) && root.parkForToken("pull", job.index, remote.url)) {
            root.logOperation(job.index, remote.name, "pull", "Info", "Waiting for a token")
            root.processNext()
            return
        }

        let status = "Failed"
        let detail = message
        if (/local changes/i.test(message)) {
            status = "Local changes"
            detail = "Commit or stash local changes, then pull again"
        } else if (/non-fast-forward/i.test(message)) {
            status = "Diverged"
            detail = "Local and remote history diverged; merge or rebase manually"
        } else if (/detached HEAD/i.test(message)) {
            status = "Skipped"
            detail = "Detached HEAD"
        } else if (/no commits yet/i.test(message)) {
            status = "Skipped"
            detail = "Repository has no commits yet"
        } else if (/not found after fetch/i.test(message)) {
            status = "No upstream"
            detail = "The branch does not exist on " + remote.name
        } else if (root.isAuthError(message)) {
            detail = root.pat === "skip" ? "No token provided" : "Authentication failed"
        }

        root.setStatus(job.index, status, detail)
        root.logOperation(job.index, remote.name, "pull", status === "Failed" ? "Failed" : "Info", message)
        root.processNext()
    }

    /* Children
    * ****************************************************************************************/
    ListModel { id: reposModel }

    RemoteController { id: worker }
    BranchController { id: branchReader }

    Connections {
        target: worker

        function onFetchProgress(progress) {
            if (root._job && progress >= 0)
                reposModel.setProperty(root._job.index, "progress", progress)
        }
    }

    Connections {
        target: root.gitScanner

        function onPathFound(path) {
            scanWaiter.message = "Found " + path
        }

        function onScanFinished(paths) {
            root.isOpening = true
            let handles = []
            let remotesList = []

            try {
                paths.forEach(path => {
                    const name = path.split('/').pop() || path.split('\\').pop() || "Repository"
                    let branch = ""
                    let remotes = []

                    const handle = root.repositoryController.openDetached(path)
                    if (handle) {
                        branchReader.currentRepo = handle
                        worker.currentRepo = handle
                        branch = branchReader.getCurrentBranchName()

                        const res = worker.getRemotes()
                        if (res.success)
                            remotes = res.data.map(r => ({ name: r.name, url: r.url || "" }))
                    }

                    handles.push(handle)
                    remotesList.push(remotes)
                    reposModel.append({
                        name:        name,
                        path:        path,
                        branchName:  branch || "detached",
                        remotesText: remotes.map(r => r.name).join(", "),
                        status:      "Ready",
                        detail:      "",
                        progress:    -1
                    })
                })
            } finally {
                branchReader.currentRepo = null
                worker.currentRepo = null
                root._repoHandles = handles
                root._repoRemotes = remotesList
                root.selectedIndexes = Array.from({ length: reposModel.count }, (_, i) => i)
                root.isOpening = false
            }
        }
    }

    Connections {
        target: root.userAuthenticationPopup
        enabled: root._awaitingAuth

        function onPasswordConfirm(password) {
            root._awaitingAuth = false
            root.pat = password
            const waiting = root._authWaiting
            root._authWaiting = []
            root.logOperation(-1, "", "auth", "Info", "Token provided, retrying " + waiting.length + " repositories")
            waiting.forEach(op => root.enqueue(op.operation, op.index))
        }

        function onRejected() {
            root._awaitingAuth = false
            root.pat = "skip"
            root._authWaiting.forEach(op => {
                root.setStatus(op.index, "Skipped", "No token provided")
                root.logOperation(op.index, "", op.operation, "Skipped", "No token provided")
            })
            root._authWaiting = []
        }
    }

    component ToolbarButton: AbstractButton {
        id: toolbarButton

        property string iconText: ""
        property bool   primary:  false
        property bool   danger:   false

        implicitHeight: 30
        implicitWidth: buttonRow.implicitWidth + (text.length > 0 ? 22 : 16)
        hoverEnabled: true
        opacity: enabled ? 1.0 : 0.45

        background: Rectangle {
            radius: 6
            color: toolbarButton.primary
                   ? (toolbarButton.hovered ? Style.colors.accentHover : Style.colors.accent)
                   : (toolbarButton.hovered ? Style.colors.controlBackgroundHover : Style.colors.controlBackground)
            border.width: toolbarButton.primary ? 0 : 1
            border.color: toolbarButton.danger && toolbarButton.hovered ? Style.colors.error : Style.colors.controlBorder

            Behavior on color { ColorAnimation { duration: Style.motionFast } }
        }

        contentItem: Item {
            Row {
                id: buttonRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: toolbarButton.iconText.length > 0
                    text: toolbarButton.iconText
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.captionPt
                    color: toolbarButton.primary ? Style.colors.onAccentText
                         : toolbarButton.danger ? Style.colors.error : Style.colors.foreground
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: toolbarButton.text.length > 0
                    text: toolbarButton.text
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    font.weight: Font.Medium
                    color: toolbarButton.primary ? Style.colors.onAccentText : Style.colors.foreground
                }
            }
        }

        HoverHandler { cursorShape: toolbarButton.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 14

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "repo_forest_popup_tutorial"
            guideName: "Repo Forest"
            guideIcon: Style.icons.tree
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return repoListView },
                        icon: Style.icons.tree,
                        title: "Discovered Repositories",
                        description: "Every git repository found under the selected folder is listed here. Click a row to include or exclude it from bulk operations.",
                        isInPopup: true
                    },
                    {
                        targetProvider: function() { return fetchButton },
                        icon: Style.icons.download,
                        title: "Fetch",
                        description: "Fetches every remote of each selected repository, one repository at a time.",
                        commands: [{ command: "git fetch --all" }],
                        isInPopup: true
                    },
                    {
                        targetProvider: function() { return pullButton },
                        icon: Style.icons.arrowDown,
                        title: "Pull",
                        description: "Fast-forwards each selected repository from the remote its branch tracks. Repositories with conflicting local changes or diverged history are left untouched and flagged.",
                        commands: [{ command: "git pull --ff-only" }],
                        isInPopup: true
                    }
                ]
            }
        }

        // ── Header ─────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 8
                color: Style.colors.accentWash

                Text {
                    anchors.centerIn: parent
                    text: Style.icons.tree
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: Style.appFont.largePt
                    color: Style.colors.accent
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Text {
                    text: "Repo Forest"
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.h4Pt
                    font.weight: Font.DemiBold
                    color: Style.colors.foreground
                }

                Text {
                    Layout.fillWidth: true
                    text: root.rootPath
                    elide: Text.ElideMiddle
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.captionPt
                    color: Style.colors.secondaryText
                }
            }

            WindowsButton {
                id: closeButton

                Material.accent: Style.colors.windowsClose
                content: Item {
                    anchors.centerIn: parent
                    width: 10
                    height: 10

                    Rectangle {
                        width: 12
                        height: 2
                        radius: 1
                        color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                        anchors.centerIn: parent
                        rotation: 45
                    }

                    Rectangle {
                        width: 12
                        height: 2
                        radius: 1
                        color: closeButton.containsMouse ? Style.colors.primaryBackground : Style.colors.foreground
                        anchors.centerIn: parent
                        rotation: -45
                    }
                }
                onClicked: root.closeRequested()
            }
        }

        // ── Toolbar ────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            CheckBox {
                id: selectAllCheckBox
                enabled: root.repoCount > 0
                tristate: true
                checkState: root.allSelected ? Qt.Checked : root.someSelected ? Qt.PartiallyChecked : Qt.Unchecked
                text: root.repoCount === 0 ? "No repositories"
                                           : root.selectedCount + " of " + root.repoCount + " selected"

                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.captionPt

                Material.accent: Style.colors.accent
                Material.foreground: Style.colors.foreground

                onClicked: root.toggleSelectAll()
            }

            CheckBox {
                id: autoScrollCheckBox
                text: "Follow progress"
                checked: true

                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.captionPt

                Material.accent: Style.colors.accent
                Material.foreground: Style.colors.foreground
            }

            Item { Layout.fillWidth: true }

            ToolbarButton {
                id: fetchButton
                visible: root.isIdle
                enabled: !root.noneSelected
                iconText: Style.icons.download
                text: "Fetch"
                onClicked: root.enqueueSelected("fetch")
            }

            ToolbarButton {
                id: pullButton
                visible: root.isIdle
                enabled: !root.noneSelected
                primary: true
                iconText: Style.icons.arrowDown
                text: "Pull"
                onClicked: root.enqueueSelected("pull")
            }

            ToolbarButton {
                readonly property bool paused: root.queueState === RepoForest.QueueState.Pause
                                               || root.queueState === RepoForest.QueueState.PauseRequested
                visible: !root.isIdle
                enabled: root.queueState !== RepoForest.QueueState.Stop
                iconText: paused ? Style.icons.play : Style.icons.pause
                text: paused ? "Resume" : "Pause"
                onClicked: paused ? root.resumeQueue() : root.pauseQueue()
            }

            ToolbarButton {
                visible: !root.isIdle
                enabled: root.queueState !== RepoForest.QueueState.Stop
                danger: true
                iconText: Style.icons.stop
                text: "Stop"
                onClicked: root.stopQueue()
            }
        }

        // ── Progress summary ───────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            visible: root.touchedCount > 0
            radius: 8
            color: Style.colors.utilitiesSurfaceBackground
            border.width: 1
            border.color: Style.colors.utilitiesSurfaceBorder

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.topMargin: 10
                anchors.bottomMargin: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    BusyIndicator {
                        Layout.preferredWidth: 16
                        Layout.preferredHeight: 16
                        running: root.queueState === RepoForest.QueueState.Running
                        visible: running
                        Material.accent: Style.colors.accent
                    }

                    Text {
                        Layout.fillWidth: true
                        text: {
                            let state = ""
                            switch (root.queueState) {
                            case RepoForest.QueueState.Running:        state = "Working"; break
                            case RepoForest.QueueState.PauseRequested: state = "Pausing after the current repository"; break
                            case RepoForest.QueueState.Pause:          state = "Paused"; break
                            case RepoForest.QueueState.Stop:           state = "Stopping after the current repository"; break
                            default:                                   state = "Finished"; break
                            }
                            let text = state + " · " + root.finishedCount + " of " + root.touchedCount + " done"
                            if (root.failedCount > 0)
                                text += " · " + root.failedCount + " need attention"
                            return text
                        }
                        elide: Text.ElideRight
                        font.family: Style.fontTypes.inter
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.foreground
                    }

                    Text {
                        text: root.progressPercent + "%"
                        font.family: Style.fontTypes.jetBrainsMono
                        font.pixelSize: Style.appFont.captionPt
                        font.weight: Font.Bold
                        color: Style.colors.accent
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 4
                    radius: 2
                    color: Style.colors.primaryBorder

                    Rectangle {
                        height: parent.height
                        width: parent.width * (root.progressPercent / 100)
                        radius: 2
                        color: root.failedCount > 0 && root.isIdle ? Style.colors.warning : Style.colors.accent
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }
                }
            }
        }

        // ── Content ────────────────────────────────────────────────────
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            BusyWaiter {
                id: scanWaiter
                anchors.centerIn: parent
                running: root.gitScanner.busy || root.isOpening
                visible: running
            }

            EmptyStateView {
                anchors.fill: parent
                visible: root.repoCount === 0 && !root.gitScanner.busy && !root.isOpening
                title: "No repositories found"
                details: "No Git repository was found under " + root.rootPath
            }

            ListView {
                id: repoListView
                anchors.fill: parent
                visible: root.repoCount > 0 && !root.gitScanner.busy && !root.isOpening
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds
                model: reposModel

                ScrollBar.vertical: ScrollBar {}

                delegate: RepoItem {
                    id: repoDelegate

                    width: ListView.view.width - 12
                    statusKind: root.kindOf(repoDelegate.status)
                    isSelected: root.selectedIndexes.indexOf(repoDelegate.index) !== -1
                    isBusy: root.isQueuedOrRunning(repoDelegate.index)

                    onClicked: root.toggleSelection(repoDelegate.index)
                    onFetchRequested: root.enqueue("fetch", repoDelegate.index)
                    onPullRequested: root.enqueue("pull", repoDelegate.index)
                }
            }
        }

        RepoForestLogs {
            Layout.fillWidth: true
            visible: root.operationLogs.length > 0
            operationLogs: root.operationLogs

            onClearLogsRequested: root.operationLogs = []
        }
    }
}
