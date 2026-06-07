import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RepoForest
 * RepoForest : find all repositories and can pull, fetch all (or selected) items.
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
    property   var                          reposModel:               []
    property   var                          selectedIndexes:          []
    property   bool                         isRunning:                false
    property   var                          operationQueue:           []
    property   int                          queueState:               RepoForest.QueueState.Ready
    property   var                          scannedRepositories:      []

    property   string                       pat:                      ""
    property   string                       pendingOperation:         ""

    property   bool                         fetchFlowActive:          false
    property   int                          fetchFlowItemIndex:       -1
    property   var                          fetchFlowRemotes:         []
    property   int                          fetchFlowRemoteIndex:     0
    property   string                       fetchFlowCurrentRemote:   ""

    property   var                          operationLogs:            []


    readonly property bool allSelected:     reposModel.length > 0 && selectedIndexes.length === reposModel.length
    readonly property bool noneSelected:    selectedIndexes.length === 0
    readonly property bool someSelected:    !allSelected && !noneSelected

    readonly property int selectedCount:    root.selectedIndexes.length

    readonly property int completedCount: {
        let count = 0
        root.selectedIndexes.forEach(idx => {
            let status = root.reposModel[idx] ? root.reposModel[idx].status : ""
            if (status === "Done" || status === "Canceled") {
                count++
            }
        })
        return count
    }

    readonly property int progressPercent: root.selectedCount > 0 ? Math.round((root.completedCount / root.selectedCount) * 100) : 0

    readonly property int pendingFetchCount: {
        let count = 0
        root.operationQueue.forEach(op => {
            if (op.operation === "fetch")
                count++
        })

        if (root.fetchFlowActive)
            count++

        return count
    }

    readonly property int pendingPullCount: {
        let count = 0
        root.operationQueue.forEach(op => {
            if (op.operation === "pull")
                count++
        })
        root.selectedIndexes.forEach(idx => {
            if (root.reposModel[idx] && root.reposModel[idx].status === "Pulling")
                count++
        })
        return count
    }

    /* Private Properties
     * ****************************************************************************************/
    property string _currentOperation: ""
    property var    _patWaitingIndexs: []
    property bool   _showUserAuthenticationPopup: false

    on_ShowUserAuthenticationPopupChanged: {
        if (root._showUserAuthenticationPopup && root.pat === "") {
            root.userAuthenticationPopup.open()
        }
    }

    /* Signals
    * ****************************************************************************************/
    signal closeRequested()

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground
    radius: 16
    clip: true
    border.color: Style.colors.accent
    border.width: 1

    /* Functions
    * ****************************************************************************************/
    function toggleSelection(index) {
        let arr = root.selectedIndexes.slice()
        let pos = arr.indexOf(index)
        if (pos === -1)
            arr.push(index)
        else
            arr.splice(pos, 1)
        root.selectedIndexes = arr
    }

    function toggleSelectAll() {
        if (root.allSelected)
            root.selectedIndexes = []
        else
            root.selectedIndexes = Array.from({ length: root.reposModel.length }, (_, i) => i)
    }

    function updateStatus(itemIndex: int, status: string) {
        root.reposModel[itemIndex].status = status

        root.reposModel = root.reposModel.slice()
    }

    function logOperation(repoName, remoteName, operation, status, message) {
        let entry = {
            repoName: repoName,
            remoteName: remoteName,
            operation: operation,
            status: status,
            message: message,
            timestamp: new Date().toLocaleTimeString(Qt.locale(), "hh:mm:ss")
        }
        root.operationLogs.push(entry)
        root.operationLogs = root.operationLogs.slice()
    }

    function enqueueOperation(operation, itemIndex) {
        root.operationQueue.push({ operation: operation, index: itemIndex})
        root.operationQueue = root.operationQueue.slice()
        root.updateStatus(itemIndex, "Pending")

        if (root.queueState === RepoForest.QueueState.Ready) {
            processNextOperation()
        }
    }

    function processNextOperation() {
        if (root.operationQueue.length === 0) {
            root.queueState = RepoForest.QueueState.Ready
            return
        }

        if (root.queueState === RepoForest.QueueState.PauseRequested) {
            root.queueState = RepoForest.QueueState.Pause
            return
        }

        if (root.queueState === RepoForest.QueueState.Pause) {
            return
        }

        if (root.queueState === RepoForest.QueueState.Stop) {
            let queue = root.operationQueue.slice()

            root.logOperation("","", "Stop", "Info", "Queue Stop")

            root.operationQueue = []
            root.operationQueue = root.operationQueue.slice()
            for (let i = 0; i < queue.length; i++) {
                root.updateStatus(queue[i].index, "Stoped")
            }

            root.queueState = RepoForest.QueueState.Ready
            root.fetchFlowActive = false
            root.fetchFlowItemIndex = -1
            root.fetchFlowRemotes = []
            root.fetchFlowRemoteIndex = 0
            root.fetchFlowCurrentRemote = ""
            root._currentOperation = ""
            root._patWaitingIndexs = []
            return
        }

        root.queueState = RepoForest.QueueState.Running
        let item = root.operationQueue.shift()
        root.operationQueue = root.operationQueue.slice()

        if (item.operation === "fetch") {
            root._currentOperation = item.operation
            executeFetch(item.index)
        } else if (item.operation === "pull") {
            root._currentOperation = item.operation
            executePull(item.index)
        }
    }

    function pauseQueue() {
        root.queueState = RepoForest.QueueState.PauseRequested
        root.logOperation("","", "pause", "Info", "Queue paused")
    }

    function resumeQueue() {
        if (root.queueState === RepoForest.QueueState.Pause) {
            root.logOperation("","", "resume", "Info", "Queue resumed")
            root.queueState = RepoForest.QueueState.Ready
            if (root.operationQueue.length > 0) {
                processNextOperation()
            }
        }
    }

    function executeFetch(itemIndex: int) {
        root.updateStatus(itemIndex, "Fetching")

        let repoItem = root.reposModel[itemIndex]

        if(!repoItem.repo) {
            root.updateStatus(itemIndex, "Canceled")
            root.logOperation(repoItem.name, "", "fetch", "Canceled", "Repository not available")
            processNextOperation()
            return
        }

        scanRemoteController.currentRepo = repoItem.repo

        let remotesRes = scanRemoteController.getRemotes()

        if(!remotesRes.success) {
            root.updateStatus(itemIndex, "Canceled")
            root.logOperation(repoItem.name, "", "fetch", "Canceled", "Failed to get remotes")
            processNextOperation()
            return
        }

        if (remotesRes.data.length === 0) {
            root.updateStatus(itemIndex, "Done")
            root.logOperation(repoItem.name, "", "fetch", "Done", "No remotes to fetch")
            processNextOperation()
            return
        }

        root.fetchFlowActive        = true
        root.fetchFlowItemIndex     = itemIndex
        root.fetchFlowRemotes       = remotesRes.data
        root.fetchFlowRemoteIndex   = 0
        root.fetchFlowCurrentRemote = ""

        fetchStartNextRemote()
    }

    function fetchStartNextRemote() {
        if (!root.fetchFlowActive)
            return

        if (root.fetchFlowRemoteIndex >= root.fetchFlowRemotes.length) {
            finishFetchFlow("Done")
            return
        }

        let remote = root.fetchFlowRemotes[root.fetchFlowRemoteIndex]
        let repoName = root.reposModel[root.fetchFlowItemIndex].name
        root.fetchFlowRemoteIndex += 1
        root.fetchFlowCurrentRemote = remote.name

        root.logOperation(repoName, remote.name, "fetch", "Fetching", "Starting fetch...")

        let remoteUrlRes = scanRemoteController.getRemoteUrl(remote.name)
        if(!remoteUrlRes.success) {
            root.logOperation(repoName, remote.name, "fetch", "Canceled", "Failed to get remote URL")
            finishFetchFlow("Canceled")
            return
        }

        let protocol = root.repositoryController.detectGitProtocol(remoteUrlRes.data.url)

        if (protocol !== RepositoryController.GitProtocol.SSH) {
            if (root.pat === "") {
                root._patWaitingIndexs.push(root.fetchFlowItemIndex)

                root._showUserAuthenticationPopup = true
                root.finishFetchFlow("PAT waiting")
                return
            } else if (root.pat === "skip") {
                root.logOperation(repoName, remote.name, "fetch", "Canceled", "HTTPS Skipped")
                root.finishFetchFlow("Skipped")
                return
            }
        }

        if (protocol === RepositoryController.GitProtocol.SSH) {
            scanRemoteController.fetch(remote.name)
        } else {
            scanRemoteController.fetchWithToken(remote.name, root.pat)
        }
    }

    function finishFetchFlow(status: string) {
        let idx = root.fetchFlowItemIndex
        let repoName = root.reposModel[idx].name
        if (status === "Done") {
            root.logOperation(repoName, "", "fetch", "Done", "All remotes fetched successfully")
        } else if (status === "Canceled") {
            root.logOperation(repoName, root.fetchFlowCurrentRemote, "fetch", "Canceled", "Fetch canceled or failed")
        } else if (status === "PAT waiting") {
            root.logOperation(repoName, root.fetchFlowCurrentRemote, "fetch", "Canceled", "Waiting for PAT")
        }

        root.fetchFlowActive        = false
        root.fetchFlowItemIndex     = -1
        root.fetchFlowRemotes       = []
        root.fetchFlowRemoteIndex   = 0
        root.fetchFlowCurrentRemote = ""

        root.updateStatus(idx, status)
        processNextOperation()
    }

    function executePull(itemIndex: int, pat: string) {
        root.updateStatus(itemIndex, "Pulling")

        let repoItem = root.reposModel[itemIndex]

        if(!repoItem || !repoItem.repo) {
            root.updateStatus(itemIndex, "Canceled")
            root.logOperation("Unknown", "", "pull", "Canceled", "Repository not available")
            processNextOperation()
            return
        }

        scanRemoteController.currentRepo = repoItem.repo
        let remotesRes = scanRemoteController.getRemotes()

        if(!remotesRes.success) {
            root.updateStatus(itemIndex, "Canceled")
            root.logOperation(repoItem.name, "", "pull", "Canceled", "Failed to get remotes")
            processNextOperation()
            return
        }

        if (remotesRes.data.length === 0) {
            root.updateStatus(itemIndex, "Done")
            root.logOperation(repoItem.name, "", "pull", "Done", "No remotes to pull")
            processNextOperation()
            return
        }

        remotesRes.data.forEach(remote => {
            let remoteUrlRes = scanRemoteController.getRemoteUrl(remote.name)

            if(!remoteUrlRes.success) {
                root.updateStatus(itemIndex, "Canceled")
                root.logOperation(repoItem.name, remote.name, "pull", "Canceled", "Failed to get remote URL")
                processNextOperation()
                return
            }

            let protocol = root.repositoryController.detectGitProtocol(remoteUrlRes.data.url)

            if (protocol !== RepositoryController.GitProtocol.SSH && pat === "") {
                root.reposModel[itemIndex].pendingOperation = "pull"
                root.reposModel = root.reposModel.slice()
                root.updateStatus(itemIndex, "PAT waiting")
                processNextOperation()
                return
            }

            if (protocol === RepositoryController.GitProtocol.SSH) {
                let onPullFinished = (result) => {
                    if (result.success) {
                        root.updateStatus(itemIndex, "Done")
                        root.logOperation(repoItem.name, remote.name, "pull", "Success", "Pull completed successfully")
                    } else {
                        root.updateStatus(itemIndex, "Canceled")
                        root.logOperation(repoItem.name, remote.name, "pull", "Failed", result.error || "Pull failed")
                    }
                    scanRemoteController.pullFinished.disconnect(onPullFinished)
                    processNextOperation()
                }

                scanRemoteController.pullFinished.connect(onPullFinished)

                let pullRes = scanRemoteController.pull(remote.name)
                if(!pullRes.success) {
                    root.updateStatus(itemIndex, "Canceled")
                    root.logOperation(repoItem.name, remote.name, "pull", "Canceled", "Failed to start pull")
                    scanRemoteController.pullFinished.disconnect(onPullFinished)
                    processNextOperation()
                }
            } else {
                let onPullFinished = (result) => {
                    if (result.success) {
                        root.updateStatus(itemIndex, "Done")
                        root.logOperation(repoItem.name, remote.name, "pull", "Success", "Pull completed successfully")
                    } else {
                        root.updateStatus(itemIndex, "Canceled")
                        root.logOperation(repoItem.name, remote.name, "pull", "Failed", result.error || "Pull failed")
                    }
                    scanRemoteController.pullFinished.disconnect(onPullFinished)
                    processNextOperation()
                }
                scanRemoteController.pullFinished.connect(onPullFinished)
                let pullRes = scanRemoteController.pull(remote.name, "", pat)
                if(!pullRes.success) {
                    root.updateStatus(itemIndex, "Canceled")
                    root.logOperation(repoItem.name, remote.name, "pull", "Canceled", "Failed to start pull")
                    scanRemoteController.pullFinished.disconnect(onPullFinished)
                    processNextOperation()
                }
            }
        })
    }

    function fetch(itemIndex: int) {
        enqueueOperation("fetch", itemIndex)
    }

    function pull(itemIndex: int) {
        enqueueOperation("pull", itemIndex)
    }

    function fetchSelectedIndexes() {
        root.selectedIndexes.forEach(index => {
            root.fetch(index)
        })
    }

    function pullSelectedIndexes() {
        root.selectedIndexes.forEach(index => {
            root.pull(index)
        })
    }

    /* Children
    * ****************************************************************************************/
    BranchController {
        id: scanBranchController
    }

    RemoteController {
        id: scanRemoteController
    }

    Connections {
        target: scanRemoteController

        function onFetchFinished(result) {
            if (!root.fetchFlowActive || !result || !result.remote)
                return

            if (result.remote !== root.fetchFlowCurrentRemote)
                return

            let repoName = root.reposModel[root.fetchFlowItemIndex].name
            if (result.success) {
                root.logOperation(repoName, result.remote, "fetch", "Success", "Fetch completed successfully")
                fetchStartNextRemote()
            } else {
                root.logOperation(repoName, result.remote, "fetch", "Failed", result.error || "Fetch failed")
                finishFetchFlow("Canceled")
            }
        }

        function onFetchProgress(progress) {
            let idx = root.fetchFlowItemIndex

            root.reposModel[idx].progress = progress
            root.reposModel = root.reposModel.slice()
        }
    }

    Connections {
        target: gitScanner

        function onPathFound(path) {
            busyWaiter.message = "Find " + path
        }

        function onScanFinished(paths) {
            root.isRunning = true
            root.scannedRepositories = []

            try {
                paths.forEach(path => {
                    let repoName = path.split('/').pop() || path.split('\\').pop() || "Repository"
                    let brancName = "none"
                    let remote = ""

                    busyWaiter.message = "open " + path

                    let repoHandle = repositoryController.openDetached(path)

                    if(repoHandle) {
                        root.scannedRepositories.push(repoHandle)
                        scanBranchController.currentRepo = repoHandle
                        scanRemoteController.currentRepo = repoHandle

                        busyWaiter.message = "get " + path
                        brancName = scanBranchController.getCurrentBranchName()

                        let remoteRes = scanRemoteController.getRemotes()
                        if(remoteRes.success){
                            remote = remoteRes.data
                                .map(remoteItem => remoteItem.url)
                                .filter(url => url && url.length > 0)
                                .join(", ")
                        }
                    }

                    busyWaiter.message = "Done " + path

                    root.reposModel.push({ repo: repoHandle, name: repoName, path: path, branchName: brancName, remote: remote, status: "Pending"})
                })
            } finally {
                scanBranchController.currentRepo = null
                scanRemoteController.currentRepo = null


                root.scannedRepositories = []
                root.reposModel = root.reposModel.slice()
                root.isRunning = false
            }
        }
    }

    Connections {
        target: root.userAuthenticationPopup

        function onPasswordConfirm(password){
            root.pat = password

            root._patWaitingIndexs.forEach(index => {
                if (root._currentOperation === "fetch") {
                    root.fetch(index)
                } else if (root._currentOperation === "pull"){
                    root.pull(index)
                }
            })

            root._patWaitingIndexs = []
        }

        function onRejected() {
            root.pat = "skip"

            root._patWaitingIndexs.forEach(index => {
                root.updateStatus(index, "Skipped")
                let repoName = root.reposModel[index].name || ""
                if (repoName !== "")
                    root.logOperation(repoName, "", "fetch", "Canceled", "HTTPS Skipped")
            })

            root._patWaitingIndexs = []
        }

        function onClosed() {
            root._showUserAuthenticationPopup = false
        }
    }

    onRootPathChanged: {
        root.reposModel = []
        root.selectedIndexes = []
        gitScanner.scan(root.rootPath)
    }

    ColumnLayout {
        spacing: 4
        anchors.fill: parent
        anchors.margins: 20

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            FormInputField {
                Layout.fillWidth: true
                field.readOnly: true
                field.text: root.rootPath
                icon: Style.icons.folder
            }

            CheckBox {
                id: selectAllCheckBox
                Layout.fillWidth: false
                text: "Select All"

                font.family: Style.fontTypes.roboto
                font.pixelSize: 12

                Material.accent: Style.colors.accent
                Material.foreground: Style.colors.foreground

                palette {
                    text: Style.colors.foreground
                }

                checkState: root.allSelected ? Qt.Checked : root.someSelected ? Qt.PartiallyChecked : Qt.Unchecked

                tristate: true

                onClicked: {
                    root.toggleSelectAll()
                }
            }

            ToolButton {
                id: fetchButton
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                enabled: !root.noneSelected && root.queueState === RepoForest.QueueState.Ready
                visible: root.queueState === RepoForest.QueueState.Ready
                hoverEnabled: true

                contentItem: Text {
                    anchors.centerIn: parent
                    text: Style.icons.download
                    font.pixelSize: 15
                    font.family: Style.fontTypes.font6ProSolid
                    color: fetchButton.enabled ? Style.colors.foreground : Style.colors.mutedText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 5
                    color: !fetchButton.enabled ? Style.colors.primaryBackground :
                           fetchButton.down ? Style.colors.surfaceMuted :
                           fetchButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                ToolTip {
                    visible: fetchButton.hovered
                    delay: 100
                    timeout: 2000

                    x: (parent.width - width) / 2
                    y: -height - 6

                    padding: 6

                    contentItem: Text {
                        text: "Fetch"
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

                onClicked: root.fetchSelectedIndexes()
            }

            ToolButton {
                id: pullButton
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26

                enabled: !root.noneSelected && root.queueState === RepoForest.QueueState.Ready
                visible: root.queueState === RepoForest.QueueState.Ready
                hoverEnabled: true

                contentItem: Text {
                    anchors.centerIn: parent
                    text: Style.icons.arrowDown
                    font.pixelSize: 15
                    font.family: Style.fontTypes.font6ProSolid
                    color: pullButton.enabled ? Style.colors.foreground : Style.colors.mutedText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 5
                    color: !pullButton.enabled ? Style.colors.primaryBackground :
                           pullButton.down ? Style.colors.surfaceMuted :
                           pullButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                ToolTip {
                    visible: pullButton.hovered
                    delay: 100
                    timeout: 2000

                    x: (parent.width - width) / 2
                    y: -height - 6

                    padding: 6

                    contentItem: Text {
                        text: "Pull"
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

                onClicked: root.pullSelectedIndexes()
            }

            ToolButton {
                id: pauseResumeButton

                property bool isQueuePaused: root.queueState === RepoForest.QueueState.Pause

                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                visible: root.queueState === RepoForest.QueueState.Running || root.queueState === RepoForest.QueueState.Pause
                enabled: (root.queueState === RepoForest.QueueState.Running || root.queueState === RepoForest.QueueState.Pause) && root.queueState !== RepoForest.QueueState.PauseRequested
                hoverEnabled: true

                contentItem: Text {
                    anchors.centerIn: parent
                    text: pauseResumeButton.isQueuePaused ? Style.icons.play : Style.icons.pause
                    font.pixelSize: 15
                    font.family: Style.fontTypes.font6ProSolid
                    color: Style.colors.foreground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 5
                    color: pauseResumeButton.down ? Style.colors.surfaceMuted :
                           pauseResumeButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                ToolTip {
                    visible: pauseResumeButton.hovered
                    delay: 100
                    timeout: 2000

                    x: (parent.width - width) / 2
                    y: -height - 6

                    padding: 6

                    contentItem: Text {
                        text: pauseResumeButton.isQueuePaused ? "Resume" : "Pause"
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

                onClicked: {
                    if (pauseResumeButton.isQueuePaused) {
                        root.resumeQueue()
                    } else {
                        root.pauseQueue()
                    }
                }
            }

            ToolButton {
                id: stopButton
                Layout.preferredWidth: 26
                Layout.preferredHeight: 26
                visible: root.queueState === RepoForest.QueueState.Running || root.queueState === RepoForest.QueueState.Pause
                enabled: (root.queueState === RepoForest.QueueState.Running || root.queueState === RepoForest.QueueState.Pause) && root.queueState !== RepoForest.QueueState.PauseRequested
                hoverEnabled: true

                contentItem: Text {
                    anchors.centerIn: parent
                    text: Style.icons.stop
                    font.pixelSize: 15
                    font.family: Style.fontTypes.font6ProSolid
                    color: Style.colors.foreground
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 5
                    color: stopButton.down ? Style.colors.surfaceMuted :
                           stopButton.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                ToolTip {
                    visible: stopButton.hovered
                    delay: 100
                    timeout: 2000

                    x: (parent.width - width) / 2
                    y: -height - 6

                    padding: 6

                    contentItem: Text {
                        text: "Stop All"
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

                onClicked: {
                    let lastState = root.queueState
                    root.queueState = RepoForest.QueueState.Stop
                    if (lastState === RepoForest.QueueState.Pause) {
                        processNextOperation()
                    }
                }
            }

            WindowsButton {
                id: closeButton

                Layout.leftMargin: 40

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

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            color: Style.colors.secondaryBackground
            radius: 6
            visible: root.selectedCount > 0

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 6

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "Selected: " + root.selectedCount
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 11
                        color: Style.colors.foreground
                    }
                    Text {
                        text: "Pending Fetch: " + root.pendingFetchCount
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 11
                        color: Style.colors.repoItemStatusFetchingText
                    }
                    Text {
                        text: "Pending Pull: " + root.pendingPullCount
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 11
                        color: Style.colors.repoItemStatusPullingText
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    BusyIndicator {
                        id: queueSpinner
                        Layout.preferredWidth: 24
                        Layout.preferredHeight: 24
                        running: root.queueState !== RepoForest.QueueState.Ready && root.queueState !== RepoForest.QueueState.Pause
                        visible: queueSpinner.running
                        Material.accent: Style.colors.accent
                    }

                    Text {
                        text: root.progressPercent + "%"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 12
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
                        color: Style.colors.accent
                        Behavior on width { NumberAnimation { duration: 200 } }
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            Layout.leftMargin: 5
            Layout.rightMargin: 5
            radius: 10
            color: Style.colors.primaryBorder

            Behavior on Layout.preferredHeight {
                NumberAnimation { duration: 300 }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !root.reposModel || root.reposModel.length === 0 && !root.gitScanner.busy && !root.isRunning

            EmptyStateView {
                title: "Repository not found"
                details: "Path : " + root.rootPath
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.gitScanner.busy

            BusyWaiter {
                id: busyWaiter
                running: root.gitScanner.busy || root.isRunning
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.reposModel && root.reposModel.length > 0 && !root.gitScanner.busy && !root.isRunning
            clip: true

            ColumnLayout {
                width: parent.width
                spacing: 4

                Repeater {
                    id: repositoryRepeater
                    model: root.reposModel

                    delegate: RepoItem {
                        isSelected: root.selectedIndexes.indexOf(index) !== -1
                        isProcessing: root.queueState !== RepoForest.QueueState.Ready

                        onClicked: (i) => root.toggleSelection(i)
                        onFetchRequested: (i) => root.fetch(i)
                        onPullRequested: (i) => root.pull(i)
                    }
                }
            }
        }

        RepoForestLogs {
            Layout.fillWidth: true
            visible: root.operationLogs.length > 0
            operationLogs: root.operationLogs

            onClearLogsRequested: {
                root.operationLogs = []
            }
        }
    }
}
