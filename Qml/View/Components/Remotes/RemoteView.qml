import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style_Impl
import GitEase_Style
import GitEase

import "qrc:/GitEase/Qml/Core/Scripts/AsyncGit.js" as AsyncGit

/*! ***********************************************************************************************
 * RemoteView
 * ************************************************************************************************/

UtilitiesCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property int currentIndex: 0

    property RemoteController remoteController: null

    property RepositoryController repositoryController: null

    property UserAuthenticationPopup userAuthenticationPopup: null

    property UiSessionPopups uiSessionPopups: null

    property AddEditRemotePopup addEditRemotePopup: null

    property NotificationController notificationController: null

    property GuideController guideController: null

    property bool isFetching: false
    property var activeFetchRemotes: []
    property string authPurpose: "fetch" // "fetch" | "pull"

    property Remote remote: null

    /* Object Properties
     * ****************************************************************************************/

    title: "Remotes"
    icon: Style.icons.upload

    Connections {
        id: userAuthenticationPopupConnection
        target: userAuthenticationPopup
        enabled: false

        function onPasswordConfirm(password){
            if (root.authPurpose === "pull") {
                root.isFetching = true
                content.startPull([remote.name, "", password], remote.name)
            } else {
                root.isFetching = true
                if (root.activeFetchRemotes.indexOf(remote.name) === -1)
                    root.activeFetchRemotes.push(remote.name)
                content.startFetch(remote.name)
            }
            root.authPurpose = "fetch"
        }

        function onRejected() {
            root.authPurpose = "fetch"
            root.isFetching = root.activeFetchRemotes.length > 0
        }

        function onClosed() {
            userAuthenticationPopupConnection.enabled = false
        }
    }

    content: ColumnLayout {
        id: content
        anchors.fill: parent
        anchors.leftMargin: Style.dp(10)
        anchors.rightMargin: Style.dp(10)
        spacing: 6

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "remotes_tutorial"
            guideName: "Remotes"
            guideIcon: Style.icons.upload
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return root },
                        icon: Style.icons.upload,
                        title: "Remotes Dock",
                        description: "Manage all git remotes for this repository. Click the header to expand this dock if it's collapsed.",
                        isInPopup: false,
                        activationDelay: 300,
                        onActivate: function() { root.collapsed = false }
                    },
                    {
                        targetProvider: function() { return listView },
                        icon: Style.icons.upload,
                        title: "Manage Remotes",
                        description: "Every remote configured for this repository is listed here. Use the icons on each row to fetch, pull, edit, or remove it."
                    },
                    {
                        targetProvider: function() { return addRemoteBtn },
                        icon: Style.icons.plus,
                        title: "Add Remote",
                        description: "Connect this repository to another remote — a fork, a backup, or a second host — by giving it a name and URL.",
                        commands: [{ command: "git remote add <name> <url>" }]
                    }
                ]
            }
        }

        Connections {
            target: root
            function onRemoteControllerChanged() {
                content.reload()
            }
        }

        ContextMenu {
            id: itemContextMenu
            parent: Overlay.overlay
            width: 200
        }

        ConfirmCommandDialog {
            id: confirmRemoveRemoteDialog

            onConfirmed: (context) => content.performRemoveRemote(context)
        }

        TextEdit {
            id: clipboardHelper
            visible: false
        }

        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.min(listView.contentHeight, 220)

            ListView {
                id: listView
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: Math.min(contentHeight, 220)
                spacing: 6
                clip: true

                delegate: Item {

                    property Remote currentRemote: modelData

                    width: listView.width
                    height: Style.dp(35)

                    Rectangle {
                        anchors.fill: parent
                        radius: Style.dp(4)
                        color: remoteHover.hovered ? Style.colors.utilitiesRowHoverBackground : "transparent"
                    }

                    HoverHandler {
                        id: remoteHover
                    }

                    MouseArea {
                        id: rightClickArea
                        anchors.fill: parent
                        acceptedButtons: Qt.RightButton
                        onClicked: (mouse) => {
                            var pos = mapToItem(Overlay.overlay, mouse.x, mouse.y)
                            itemContextMenu.menuModel = content.buildRemoteMenu(currentRemote)
                            itemContextMenu.x = pos.x
                            itemContextMenu.y = pos.y
                            itemContextMenu.open()
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 6
                        spacing: 4

                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignVCenter
                            spacing: 1
                            clip: true

                            ScrollingText {
                                Layout.fillWidth: true
                                text: currentRemote.name
                                color: Style.colors.utilitiesRowText
                                font.family: Style.fontTypes.inter
                                font.pixelSize: Style.appFont.mediumPt
                            }
                            ScrollingText {
                                Layout.fillWidth: true
                                text: currentRemote.url
                                color: Style.colors.utilitiesRowSubText
                                font.family: Style.fontTypes.inter
                                font.pixelSize: Style.appFont.smallPt
                            }
                        }

                        Row {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            ActionIconButton {
                                iconText: Style.icons.download
                                tooltip: root.isFetching ? "Fetching..." : "Fetch"
                                textColor: root.isFetching ? Style.colors.utilitiesActionIconActive
                                                           : Style.colors.utilitiesActionIcon
                                enabled: !root.isFetching
                                onClicked: content.fetchRemote(currentRemote)
                            }
                            ActionIconButton {
                                iconText: Style.icons.arrowDown
                                tooltip: root.isFetching ? "Pulling..." : "Pull"
                                textColor: root.isFetching ? Style.colors.utilitiesActionIconActive
                                                           : Style.colors.utilitiesActionIcon
                                enabled: !root.isFetching
                                onClicked: content.pullRemote(currentRemote)
                            }
                            ActionIconButton {
                                iconText: Style.icons.edit
                                tooltip: "Edit Remote"
                                textColor: Style.colors.utilitiesActionIcon
                                onClicked: content.editRemote(currentRemote)
                            }
                            ActionIconButton {
                                iconText: Style.icons.trash
                                tooltip: "Remove Remote"
                                textColor: Style.colors.utilitiesActionIconDanger
                                onClicked: content.removeRemoteItem(currentRemote)
                            }
                        }
                    }
                }

                onContentHeightChanged: root.pageScrollBlocking = listView.contentHeight > listView.height + 1
            }
        }

        DashedButton {
            id: addRemoteBtn
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(2)

            text: "Add Remote"

            onClicked: {
                openAddEditPopup()
            }
        }

        function reload() {
            if (remoteController) {
                let res = remoteController.getRemotes();
                if (res.success) {
                    listView.model = res.data
                    root.badgeCount = res.data.length
                }
            }
        }

        function fetchRemote(remoteItem) {
            root.remote = remoteItem
            let res = remoteController.getRemoteUrl(remoteItem.name)

            if (!res.success) {
                return
            }

            let url = res.data.url
            let protocol = repositoryController.detectGitProtocol(url)
            switch (protocol) {
            case RepositoryController.GitProtocol.SSH:
                root.isFetching = true
                if (root.activeFetchRemotes.indexOf(remoteItem.name) === -1)
                    root.activeFetchRemotes.push(remoteItem.name)
                content.startFetch(remoteItem.name)
                break;
            case RepositoryController.GitProtocol.HTTPS:
            case RepositoryController.GitProtocol.HTTP:
                root.isFetching = true
                root.authPurpose = "fetch"
                userAuthenticationPopupConnection.enabled = true
                userAuthenticationPopup.open()
                break;
            }
        }

        function pullRemote(remoteItem) {
            root.remote = remoteItem
            let res = remoteController.getRemoteUrl(remoteItem.name)

            if (!res.success) {
                return
            }

            let url = res.data.url
            let protocol = repositoryController.detectGitProtocol(url)
            switch (protocol) {
            case RepositoryController.GitProtocol.SSH:
                root.isFetching = true
                content.startPull([remoteItem.name], remoteItem.name)
                break
            case RepositoryController.GitProtocol.HTTPS:
            case RepositoryController.GitProtocol.HTTP:
                root.authPurpose = "pull"
                userAuthenticationPopupConnection.enabled = true
                userAuthenticationPopup.open()
                break
            }
        }

        function startFetch(remoteName) {
            AsyncGit.call(root.remoteController, "fetch", [remoteName],
                function(result) { content.handleFetchResult(remoteName, result) },
                function(error) { content.handleFetchResult(remoteName, { success: false, errorMessage: error, stale: error === AsyncGit.STALE }) }
            )
        }

        function handleFetchResult(remoteName, gitResult) {
            root.activeFetchRemotes = root.activeFetchRemotes.filter(function(name) { return name !== remoteName })
            root.isFetching = root.activeFetchRemotes.length > 0

            if (gitResult && gitResult.stale === true)
                root.notificationController.info("Fetch finished for the repository you switched away from", "Fetch", 4000)

            if (gitResult && gitResult.success)
                root.notificationController.success("Fetched from " + remoteName, "Fetch", 5000)
            else
                root.notificationController.error("Failed to fetch from " + remoteName + ": " + ((gitResult && gitResult.errorMessage) || "Unknown error"), "Fetch Error", 7000)
        }

        function startPull(args, remoteName) {
            AsyncGit.call(root.remoteController, "pull", args,
                function(result) { content.handlePullResult(remoteName, result) },
                function(error) { content.handlePullResult(remoteName, { success: false, errorMessage: error, stale: error === AsyncGit.STALE }) }
            )
        }

        function handlePullResult(remoteName, gitResult) {
            if (gitResult && gitResult.stale === true)
                root.notificationController.info("Pull finished for the repository you switched away from", "Pull", 4000)
            
            if (gitResult && gitResult.success)
                root.notificationController.success("Successfully pulled from " + remoteName, "Pull", 5000)
            else
                root.notificationController.error("Failed to pull from " + remoteName + ": " + ((gitResult && gitResult.errorMessage) || "Pull failed"), "Pull Error", 7000)

            root.isFetching = false
        }

        function editRemote(remoteItem) {
            addEditRemotePopup.oldRemote = remoteItem
            root.openAddEditPopup()
        }

        function removeRemoteItem(remoteItem) {
            confirmRemoveRemoteDialog.ask("Remove Remote",
                                          "Remove the remote '" + remoteItem.name + "'? Its remote-tracking branches go with it.",
                                          GitCommandText.removeRemote(remoteItem.name),
                                          "Remove Remote",
                                          remoteItem)
        }

        function performRemoveRemote(remoteItem) {
            root.remoteController.removeRemote(remoteItem.name)
        }

        function copyRemoteUrl(remoteItem) {
            clipboardHelper.text = remoteItem.url
            clipboardHelper.selectAll()
            clipboardHelper.copy()
            if (root.notificationController)
                root.notificationController.success("Remote URL copied to clipboard", "Remote", 2000)
        }

        function buildRemoteMenu(remoteItem) {
            return [
                { text: "Fetch",  icon: Style.icons.download,  enabled: !root.isFetching, action: function() { content.fetchRemote(remoteItem) } },
                { text: "Pull",   icon: Style.icons.arrowDown, enabled: !root.isFetching, action: function() { content.pullRemote(remoteItem) } },
                { separator: true },
                { text: "Edit Remote...",  icon: Style.icons.edit,      action: function() { content.editRemote(remoteItem) } },
                { text: "Remove Remote",   icon: Style.icons.trash, color: Style.colors.contextMenuDanger, action: function() { content.removeRemoteItem(remoteItem) } },
                { separator: true },
                { text: "Copy Remote URL", icon: Style.icons.copy, action: function() { content.copyRemoteUrl(remoteItem) } },
            ]
        }
    }


    /* Functions
     * ****************************************************************************************/
    function reload() {
        if (root.contentItem)
            root.contentItem.reload()
    }

    function openAddEditPopup() {
        addEditRemotePopup.remoteController = root.remoteController
        addEditRemotePopup.open()
    }

}
