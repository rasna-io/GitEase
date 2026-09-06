import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style_Impl
import GitEase_Style
import GitEase

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
                let startRes = root.remoteController.pull(remote.name, "", password)
                if (!startRes.success) {
                    if (root.notificationController)
                        root.notificationController.error(startRes.errorMessage || "Failed to start pull", "Pull Error", 5000)
                    root.isFetching = false
                    root.authPurpose = "fetch"
                    return
                }
                root.isFetching = true
            } else {
                root.isFetching = true
                let res = root.remoteController.fetchWithToken(remote.name, password)
                if (res.success) {
                    if (root.activeFetchRemotes.indexOf(remote.name) === -1)
                        root.activeFetchRemotes.push(remote.name)
                }
                else {
                    if (root.notificationController)
                        root.notificationController.error("Failed to fetch from " + remote.name + ": " + (res.errorMessage || "Unknown error"), "Fetch Error", 7000)
                    root.isFetching = root.activeFetchRemotes.length > 0
                }
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
                        title: "Add a Remote",
                        description: "Connect this repository to another remote — a fork, a backup, or a second host — by giving it a name and URL.",
                        commands: [{ command: "git remote add <name> <url>" }]
                    }
                ]
            }
        }

        Connections {
            target: root
            function onRemoteControllerChanged() {
                content.update()
            }
        }

        Connections {
            target: root.remoteController

            function onCurrentRepoChanged() {
                content.update()
            }

            // This page's own async per-remote Pull (triggered below) has no equivalent in the
            // shared RemoteOperationsSession, so it remains the sole notifier for pull results.
            function onPullFinished(result) {
                if (!root.isFetching || !root.remote || !result)
                    return

                if (result.remote !== root.remote.name)
                    return

                if (notificationController) {
                    if (result.success)
                        notificationController.success("Successfully pulled from " + root.remote.name, "Pull", 5000)
                    else
                        notificationController.error("Failed to pull from " + root.remote.name + ": " + (result.errorMessage || "Pull failed"), "Pull Error", 7000)
                }

                root.isFetching = false
                content.update()
            }
        }

        // Fetch completion notifications/summary-popup are handled once by the shared
        // RemoteOperationsSession (regardless of which UI triggered the fetch) — this only
        // tracks this card's own per-row busy state.
        Connections {
            target: root.remoteController

            function onFetchFinished(result) {
                if (!result || !result.remote)
                    return

                root.activeFetchRemotes = root.activeFetchRemotes.filter(function(name) { return name !== result.remote })
                root.isFetching = root.activeFetchRemotes.length > 0
            }
        }

        Connections {
            target: root.addEditRemotePopup

            function onAboutToHide() {
                content.update()
            }
        }

        ContextMenu {
            id: itemContextMenu
            parent: Overlay.overlay
            width: 200
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
                                tooltip: "Edit"
                                textColor: Style.colors.utilitiesActionIcon
                                onClicked: content.editRemote(currentRemote)
                            }
                            ActionIconButton {
                                iconText: Style.icons.trash
                                tooltip: "Remove"
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

        function update() {
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
                res = root.remoteController.fetch(remoteItem.name)
                if (res.success) {
                    if (root.activeFetchRemotes.indexOf(remoteItem.name) === -1)
                        root.activeFetchRemotes.push(remoteItem.name)
                } else {
                    if (root.notificationController)
                        root.notificationController.error("Failed to fetch from " + remoteItem.name + ": " + (res.errorMessage || "Unknown error"), "Fetch Error", 7000)
                }
                root.isFetching = root.activeFetchRemotes.length > 0
                content.update()
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
                let startRes = root.remoteController.pull(remoteItem.name)
                if (!startRes.success) {
                    if (root.notificationController)
                        root.notificationController.error("Failed to pull from " + remoteItem.name + ": " + (startRes.errorMessage || "Failed to start pull"), "Pull Error", 7000)
                    root.isFetching = false
                    content.update()
                    return
                }
                root.isFetching = true
                break
            case RepositoryController.GitProtocol.HTTPS:
            case RepositoryController.GitProtocol.HTTP:
                root.authPurpose = "pull"
                userAuthenticationPopupConnection.enabled = true
                userAuthenticationPopup.open()
                break
            }
        }

        function editRemote(remoteItem) {
            addEditRemotePopup.oldRemote = remoteItem
            root.openAddEditPopup()
        }

        function removeRemoteItem(remoteItem) {
            root.remoteController.removeRemote(remoteItem.name)
            content.update()
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
                { text: "Edit",   icon: Style.icons.edit,      action: function() { content.editRemote(remoteItem) } },
                { text: "Remove", icon: Style.icons.trash, color: Style.colors.contextMenuDanger, action: function() { content.removeRemoteItem(remoteItem) } },
                { separator: true },
                { text: "Copy URL", icon: Style.icons.copy, action: function() { content.copyRemoteUrl(remoteItem) } },
            ]
        }
    }


    /* Functions
     * ****************************************************************************************/

    function openAddEditPopup() {
        addEditRemotePopup.remoteController = root.remoteController
        addEditRemotePopup.open()
    }

}
