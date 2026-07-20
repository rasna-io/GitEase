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
    property var fetchBatchResults: []
    property string authPurpose: "fetch" // "fetch" | "pull"

    property Remote remote: null

    /* Signal Declarations
     * ****************************************************************************************/
    signal fetchSuccess(string remoteName)
    signal fetchError(string remoteName, string errorMessage)
    signal pullSuccess(string remoteName)
    signal pullError(string remoteName, string errorMessage)

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
                    root.pullError(remote.name, startRes.errorMessage)
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
                    root.fetchBatchResults.push({
                        remote: remote.name,
                        success: false,
                        errorMessage: res.errorMessage || "Unknown error",
                        data: { timestamp: Qt.formatDateTime(new Date(), Qt.ISODate), status: "Fetch did not start" }
                    })
                    root.fetchError(remote.name, res.errorMessage)
                    root.isFetching = root.activeFetchRemotes.length > 0
                    root.openFetchSummaryIfReady()
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

            function onPullFinished(result) {
                if (!root.isFetching || !root.remote || !result)
                    return

                if (result.remote !== root.remote.name)
                    return

                if (result.success)
                    root.pullSuccess(root.remote.name)
                else
                    root.pullError(root.remote.name, result.errorMessage || "Pull failed")

                root.isFetching = false
                content.update()
            }
        }

        Connections {
            target: root.remoteController

            function onFetchFinished(result) {
                if (!result || !result.remote)
                    return

                root.activeFetchRemotes = root.activeFetchRemotes.filter(function(name) { return name !== result.remote })
                root.fetchBatchResults.push(result)
                root.isFetching = root.activeFetchRemotes.length > 0

                if (result.success)
                    root.fetchSuccess(result.remote)
                else
                    root.fetchError(result.remote, result.errorMessage || "Unknown error")

                root.openFetchSummaryIfReady()
            }
        }

        Connections {
            target: root.uiSessionPopups ? root.uiSessionPopups.fetchSummaryPopup : null

            function onClosed() {
                root.fetchBatchResults = []
            }
        }

        Connections {
            target: root.addEditRemotePopup

            function onAboutToHide() {
                content.update()
            }
        }

        Connections {
            target: root
            
            function onFetchSuccess(remoteName) {
                if (notificationController) {
                    notificationController.success("Successfully fetched from " + remoteName, "Fetch", 5000)
                }
            }
            
            function onFetchError(remoteName, errorMessage) {
                if (notificationController) {
                    notificationController.error("Failed to fetch from " + remoteName + ": " + errorMessage, "Fetch Error", 7000)
                }
            }

            function onPullSuccess(remoteName) {
                if (notificationController) {
                    notificationController.success("Successfully pulled from " + remoteName, "Pull", 5000)
                }
            }

            function onPullError(remoteName, errorMessage) {
                if (notificationController) {
                    notificationController.error("Failed to pull from " + remoteName + ": " + errorMessage, "Pull Error", 7000)
                }
            }
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

                delegate: Rectangle {

                    property Remote currentRemote: modelData

                    width: listView.width
                    height: Style.dp(35)
                    color: Style.colors.secondaryBackground
                    radius: 4

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
                                color: Style.colors.foreground
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: Style.appFont.smallPt
                            }
                            ScrollingText {
                                Layout.fillWidth: true
                                text: currentRemote.url
                                color: Style.colors.mutedText
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: Style.appFont.captionPt
                            }
                        }

                        Row {
                            spacing: 2
                            Layout.alignment: Qt.AlignVCenter

                            ActionIconButton {
                                iconText: Style.icons.download
                                tooltip: root.isFetching ? "Fetching..." : "Fetch"
                                textColor: root.isFetching ? Style.colors.accent : Style.colors.mutedText
                                enabled: !root.isFetching
                                onClicked: {
                                    root.remote = currentRemote
                                    root.fetchBatchResults = []
                                    let res = remoteController.getRemoteUrl(currentRemote.name)

                                    if (!res.success) {
                                        return
                                    }

                                    let url = res.data.url
                                    let protocol = repositoryController.detectGitProtocol(url)
                                    switch(protocol) {
                                    case RepositoryController.GitProtocol.SSH:
                                        root.isFetching = true
                                        res = root.remoteController.fetch(currentRemote.name)
                                        if (res.success) {
                                            if (root.activeFetchRemotes.indexOf(currentRemote.name) === -1)
                                                root.activeFetchRemotes.push(currentRemote.name)
                                        } else {
                                            root.fetchBatchResults.push({
                                                remote: currentRemote.name,
                                                success: false,
                                                errorMessage: res.errorMessage || "Fetch failed",
                                                data: { timestamp: Qt.formatDateTime(new Date(), Qt.ISODate), status: "Fetch did not start" }
                                            })
                                            root.fetchError(currentRemote.name, res.errorMessage)
                                        }
                                        root.isFetching = root.activeFetchRemotes.length > 0
                                        root.openFetchSummaryIfReady()
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
                            }
                            ActionIconButton {
                                iconText: Style.icons.arrowDown
                                tooltip: root.isFetching ? "Pulling..." : "Pull"
                                textColor: root.isFetching ? Style.colors.accent : Style.colors.mutedText
                                enabled: !root.isFetching
                                onClicked: {
                                    root.remote = currentRemote
                                    let res = remoteController.getRemoteUrl(currentRemote.name)

                                    if (!res.success) {
                                        return
                                    }

                                    let url = res.data.url
                                    let protocol = repositoryController.detectGitProtocol(url)
                                    switch(protocol) {
                                    case RepositoryController.GitProtocol.SSH:
                                        let startRes = root.remoteController.pull(currentRemote.name)
                                        if (!startRes.success) {
                                            root.pullError(currentRemote.name, startRes.errorMessage || "Failed to start pull")
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
                            }
                            ActionIconButton {
                                iconText: Style.icons.edit
                                tooltip: "Edit"
                                textColor: Style.colors.mutedText
                                onClicked: {
                                    addEditRemotePopup.oldRemote = currentRemote
                                    openAddEditPopup()
                                }
                            }
                            ActionIconButton {
                                iconText: Style.icons.trash
                                tooltip: "Remove"
                                textColor: Style.colors.deletededFile
                                onClicked: {
                                    root.remoteController.removeRemote(currentRemote.name)
                                    content.update()
                                }
                            }
                        }
                    }
                }

                onContentHeightChanged: root.pageScrollBlocking = listView.contentHeight > listView.height + 1
            }
        }

        IconButton {
            id: addRemoteBtn
            Layout.fillWidth: true
            implicitHeight: Style.dp(25)

            display: IconButton.TextBesideIcon
            icon.name: Style.icons.plus
            icon.width: Style.appFont.smallPt
            icon.height: Style.appFont.smallPt
            icon.color: Style.colors.textButton
            text: "Add New Remote"
            font.pixelSize: Style.appFont.mediumPt

            background: Rectangle {
                radius: Style.dp(4)
                color: enabled ? Style.colors.accent : Style.colors.disabledButton
            }

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
    }


    /* Functions
     * ****************************************************************************************/

    function openAddEditPopup() {
        addEditRemotePopup.remoteController = root.remoteController
        addEditRemotePopup.open()
    }

    function openFetchSummaryIfReady() {
        if (root.activeFetchRemotes.length > 0 || root.fetchBatchResults.length === 0)
            return

        let popup = root.uiSessionPopups?.fetchSummaryPopup
        if (!popup)
            return

        popup.results = []
        popup.results = root.fetchBatchResults
        popup.open()
    }


}
