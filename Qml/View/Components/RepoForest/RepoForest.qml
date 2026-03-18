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

    readonly property bool allSelected:     reposModel.length > 0 && selectedIndexes.length === reposModel.length
    readonly property bool noneSelected:    selectedIndexes.length === 0
    readonly property bool someSelected:    !allSelected && !noneSelected

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

    function fetch(itemIndex: int) {
        root.updateStatus(itemIndex, "Fetching")

        let repo = root.reposModel[itemIndex]

        let openResult = root.repositoryController.open(repo.path)

        if(!openResult.success) {
            root.updateStatus(itemIndex, "Canceled")
            return
        }

        let remotesRes = root.remoteController.getRemotes()

        if(!remotesRes.success) {
            root.updateStatus(itemIndex, "Canceled")
            return
        }

        remotesRes.data.forEach((remote, remoteIndex) => {

            let remoteUrlRes = root.remoteController.getRemoteUrl(remote.name)
            if(!remoteUrlRes.success) {
                root.updateStatus(itemIndex, "Canceled")
                return
            }

            let protocol = root.repositoryController.detectGitProtocol(remoteUrlRes.data.url)
            switch(protocol) {
                case RepositoryController.GitProtocol.SSH:
                    let onFetchFinished = (result) => {
                        if(!result.success) {
                            root.updateStatus(itemIndex, "Canceled")
                            return
                        }

                        root.updateStatus(itemIndex, "Done")

                        root.remoteController.fetchFinished.disconnect(onFetchFinished)
                    }

                    root.remoteController.fetchFinished.connect(onFetchFinished)

                    let fetchRes = root.remoteController.fetch(remote.name)
                    if(!fetchRes.success) {
                        root.updateStatus(itemIndex, "Canceled")
                        return
                    }

                    break;
                case RepositoryController.GitProtocol.HTTPS:
                case RepositoryController.GitProtocol.HTTP:
                        root.updateStatus(itemIndex, "Canceled")
                    break;
            }
        })

        root.reposModel = root.reposModel.slice()
    }

    function pull(index: int) {
        // TODO
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
    Connections {
        target: gitScanner

        function onPathFound(path) {
            busyWaiter.message = "Find " + path
        }

        function onScanFinished(paths) {
            root.isRunning = true
            paths.forEach(path => {
                let repoName = path.split('/').pop() || path.split('\\').pop() || "Repository"
                let brancName = "none"
                let remote = ""

                busyWaiter.message = "open " + path

                let openRes = repositoryController.open(path)

                if(openRes.success) {
                    busyWaiter.message = "get " + path
                    brancName = branchController.getCurrentBranchName()

                    let remoteRes = remoteController.getRemotes()
                    if(remoteRes.success){

                        remoteRes.data.forEach(remoteItem => {
                                               remote += remoteItem.url + ", "
                                               })
                    }
                }

                busyWaiter.message = "Done " + path

                root.reposModel.push({ name: repoName, path: path, branchName: brancName, remote: remote, status: "Pending"})
            })

            root.reposModel = root.reposModel.slice()
            root.isRunning = false
        }
    }

    onRootPathChanged: {
        root.reposModel = []
        root.selectedIndexes = []
        gitScanner.scan(root.rootPath)
    }

    ColumnLayout {
        spacing: 8
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

                enabled: !root.noneSelected
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

                enabled: !root.noneSelected
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
                        onFetchRequested: (i) => root.fetch(i)
                        onPullRequested: (i) => root.pull(i)
                    }
                }
            }
        }
    }
}
