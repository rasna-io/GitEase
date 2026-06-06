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

    /* Property Declarations
     * ****************************************************************************************/
    property   RepositoryController   repositoryController
    property   BranchController       branchController
    property   RemoteController       remoteController
    property   string                 rootPath
    property   GitScanner             gitScanner
    property   var                    reposModel:               []
    property   var                    selectedIndexes:          []
    property   bool                   isRunning:                false
    property   var                    operationQueue:           []
    property   bool                   isProcessingQueue:        false
    property   var                    scannedRepositories:      []

    property   bool                   fetchFlowActive:          false
    property   int                    fetchFlowItemIndex:       -1
    property   string                 fetchFlowPat:             ""
    property   var                    fetchFlowRemotes:         []
    property   int                    fetchFlowRemoteIndex:     0
    property   string                 fetchFlowCurrentRemote:   ""


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

        if (status === "Canceled" || status === "Done") {
            repositoryController.closeRepository(root.reposModel[itemIndex].repo)
        }

        root.reposModel = root.reposModel.slice()
    }

    function enqueueOperation(operation, itemIndex, pat) {
        root.operationQueue.push({ operation: operation, index: itemIndex, pat: pat})
        root.operationQueue = root.operationQueue.slice()
        root.updateStatus(itemIndex, "Pending")

        if (!root.isProcessingQueue) {
            processNextOperation()
        }
    }

    function processNextOperation() {
        if (root.operationQueue.length === 0) {
            root.isProcessingQueue = false
            return
        }

        root.isProcessingQueue = true
        let item = root.operationQueue.shift()
        root.operationQueue = root.operationQueue.slice()

        if (item.operation === "fetch") {
            executeFetch(item.index, item.pat)
        } else if (item.operation === "pull") {
            executePull(item.index, item.pat)
        }
    }

    function executeFetch(itemIndex: int, pat: string) {
        root.updateStatus(itemIndex, "Fetching")

        let repoItem = root.reposModel[itemIndex]



        if(!repoItem.repo) {
            root.updateStatus(itemIndex, "Canceled")
            processNextOperation()
            return
        }

        scanRemoteController.currentRepo = repoItem.repo

        let remotesRes = scanRemoteController.getRemotes()

        if(!remotesRes.success) {
            root.updateStatus(itemIndex, "Canceled")
            processNextOperation()
            return
        }

        if (remotesRes.data.length === 0) {
            root.updateStatus(itemIndex, "Done")
            processNextOperation()
            return
        }

        root.fetchFlowActive        = true
        root.fetchFlowItemIndex     = itemIndex
        root.fetchFlowPat           = pat
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

        let remoteUrlRes = scanRemoteController.getRemoteUrl(remote.name)
        if(!remoteUrlRes.success) {
            finishFetchFlow("Canceled")

            return
        }

        let protocol = root.repositoryController.detectGitProtocol(remoteUrlRes.data.url)

        if (protocol !== RepositoryController.GitProtocol.SSH && root.fetchFlowPat === "") {
            root.reposModel[root.fetchFlowItemIndex].pendingOperation = "fetch"
            root.reposModel = root.reposModel.slice()
            root.finishFetchFlow("PAT waiting")
            return
        }

        if (protocol === RepositoryController.GitProtocol.SSH) {
            scanRemoteController.fetch(remote.name)
        } else {
            scanRemoteController.fetchWithToken(remote.name, root.fetchFlowPat)
        }
    }

    function finishFetchFlow(status: string) {
        let idx = root.fetchFlowItemIndex
        root.fetchFlowActive        = false
        root.fetchFlowItemIndex     = -1
        root.fetchFlowPat           = ""
        root.fetchFlowRemotes       = []
        root.fetchFlowRemoteIndex   = 0
        root.fetchFlowCurrentRemote = ""

        root.updateStatus(idx, status)
        processNextOperation()
    }

    function executePull(itemIndex: int, pat: string) {
        root.updateStatus(itemIndex, "Pulling")

        let repo = root.reposModel[itemIndex]

        let repoItem = root.reposModel[itemIndex]


        if(!repoItem) {
            root.updateStatus(itemIndex, "Canceled")
            processNextOperation()
            return
        }

        scanRemoteController.currentRepo = repoItem.repo
        let remotesRes = scanRemoteController.getRemotes()

        if(!remotesRes.success) {
            root.updateStatus(itemIndex, "Canceled")
            processNextOperation()
            return
        }

        if (remotesRes.data.length === 0) {
            root.updateStatus(itemIndex, "Done")
            processNextOperation()
            return
        }

        remotesRes.data.forEach(remote => {
            let remoteUrlRes = scanRemoteController.getRemoteUrl(remote.name)

            if(!remoteUrlRes.success) {
                root.updateStatus(itemIndex, "Canceled")
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
                    } else {
                        root.updateStatus(itemIndex, "Canceled")
                    }
                    scanRemoteController.pullFinished.disconnect(onPullFinished)
                    processNextOperation()
                }

                scanRemoteController.pullFinished.connect(onPullFinished)

                let pullRes = scanRemoteController.pull(remote.name)
                if(!pullRes.success) {
                    root.updateStatus(itemIndex, "Canceled")
                    scanRemoteController.pullFinished.disconnect(onPullFinished)
                    processNextOperation()
                }
            } else {
                // TODO
            }
        })
    }

    function fetch(itemIndex: int, pat: string) {
        enqueueOperation("fetch", itemIndex, pat)
    }

    function pull(itemIndex: int, pat: string) {
        enqueueOperation("pull", itemIndex, pat)
    }

    function fetchSelectedIndexes() {
        root.selectedIndexes.forEach(index => {
            root.fetch(index, "")
        })
    }

    function pullSelectedIndexes() {
        root.selectedIndexes.forEach(index => {
            root.pull(index, "")
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

            if (!result.success) {
                finishFetchFlow("Canceled")
            }else {
                fetchStartNextRemote()
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

                enabled: !root.noneSelected && !root.isProcessingQueue
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

                enabled: !root.noneSelected && !root.isProcessingQueue
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
                        running: root.isProcessingQueue
                        visible: root.isProcessingQueue
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

                        onClicked: (i) => root.toggleSelection(i)
                        onFetchRequested: (i, pat) => root.fetch(i, pat)
                        onPullRequested: (i, pat) => root.pull(i, pat)
                    }
                }
            }
        }
    }
}
