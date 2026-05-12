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

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var                     page:                    null

    property RepositoryController    repositoryController:    null

    property StatusController        statusController:        null

    property BranchController        branchController:        null

    property CommitController        commitController:        null

    property RemoteController        remoteController:        null

    property UserProfileController   userProfileController:   null

    property StashController          stashController:        null

    property NotificationController  notificationController:  null

    property UserAuthenticationPopup userAuthenticationPopup: null
    
    property UiSessionPopups         uiSessionPopups:         null

    property bool                    isFetching:             false
    property var                     activeFetchRemotes:     []
    property string                  authPurpose:            "push"  // "push" | "fetch"
    property var                     pendingFetchRemoteNames: []    // HTTP/HTTPS remotes to fetch with token
    property var                     fetchBatchResults:      []

    property string                  selectedFilePath:        ""

    property var                     actionResult:            ({})

    // Exposed to MainWindow's header area (see MainWindow.qml)
    property Component headerContent: Component {
        RowLayout {
            id: headerRow
            anchors.fill: parent
            anchors.leftMargin: parent.width < Style.appHeight ? 8 : 20
            anchors.rightMargin: parent.width < Style.appHeight ? 4 : 5
            spacing: parent.width < Style.appHeight ? 6 : 10

            readonly property bool compact: parent.width < 550

            ToolButton {
                id: branchChip
                Layout.preferredWidth: branchChipContent.implicitWidth + 20
                Layout.preferredHeight: 25
                Layout.maximumWidth: 200
                visible: !headerRow.compact
                hoverEnabled: true

                contentItem: Item {
                    Row {
                        id: branchChipContent
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: Style.icons.branch
                            font.family: Style.fontTypes.font6ProSolid
                            font.pixelSize: 11
                            color: Style.colors.foreground
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            id: headerBranchLabel
                            text: branchController ? branchController.getCurrentBranchName() : ""
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Style.colors.foreground
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            anchors.verticalCenter: parent.verticalCenter

                            Connections {
                                target: repositoryController
                                function onCurrentRepoChanged() {
                                    headerBranchLabel.text = branchController ? branchController.getCurrentBranchName() : ""
                                }
                            }
                        }
                    }
                }

                background: Rectangle {
                    radius: 5
                    color: branchChip.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }
            }

            // Separator
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 20
                color: Style.colors.primaryBorder
                visible: !headerRow.compact
            }

            ToolButton {
                id: pullBtn
                Layout.preferredWidth: headerRow.compact ? 26 : 70
                Layout.preferredHeight: 26
                hoverEnabled: true

                text: Style.icons.arrowDown
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: 13

                contentItem: Item {
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: pullBtn.text
                            font: pullBtn.font
                            color: Style.colors.foreground
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Pull"
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Style.colors.foreground
                            visible: !headerRow.compact
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                background: Rectangle {
                    radius: 5
                    color: !pullBtn.enabled ? Style.colors.primaryBackground :
                           pullBtn.down ? Style.colors.surfaceMuted :
                           pullBtn.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                onClicked: {
                    let res = remoteController.getRemoteUrl("origin")
                    if (!res.success) {
                        if (notificationController)
                            notificationController.error(res.errorMessage || "Failed to get remote URL", "Pull Error", 5000)
                        return
                    }
                    let url = res.data.url
                    let protocol = repositoryController.detectGitProtocol(url)
                    switch (protocol) {
                    case RepositoryController.GitProtocol.SSH: {
                        let pullRes = remoteController.fetch("origin")
                        if (!pullRes.success) {
                            if (notificationController)
                                notificationController.error(pullRes.errorMessage || "Pull failed", "Pull Error", 5000)
                        } else {
                            if (notificationController)
                                notificationController.success("Pulled successfully", "Pull", 3000)
                            root.update()
                        }
                        break
                    }
                    case RepositoryController.GitProtocol.HTTPS:
                    case RepositoryController.GitProtocol.HTTP:
                        root.authPurpose = "pull"
                        userAuthenticationPopup.open()
                        break
                    default:
                        if (notificationController)
                            notificationController.error("Unsupported protocol", "Pull Error", 5000)
                    }
                }

                ToolTip.visible: pullBtn.hovered
                ToolTip.text: "Pull from origin"
                ToolTip.delay: 600
            }

            ToolButton {
                id: pushBtnHeader
                Layout.preferredWidth: headerRow.compact ? 26 : 68
                Layout.preferredHeight: 26
                hoverEnabled: true

                text: Style.icons.arrowUp
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: 13

                contentItem: Item {
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: pushBtnHeader.text
                            font: pushBtnHeader.font
                            color: Style.colors.foreground
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Push"
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Style.colors.foreground
                            visible: !headerRow.compact
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                background: Rectangle {
                    radius: 5
                    color: !pushBtnHeader.enabled ? Style.colors.primaryBackground :
                           pushBtnHeader.down ? Style.colors.surfaceMuted :
                           pushBtnHeader.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                onClicked: {
                    let res = remoteController.getRemoteUrl("origin")
                    if (!res.success) {
                        if (notificationController)
                            notificationController.error(res.errorMessage || "Failed to get remote URL", "Push Error", 5000)
                        return
                    }
                    let url = res.data.url
                    let protocol = repositoryController.detectGitProtocol(url)
                    switch (protocol) {
                    case RepositoryController.GitProtocol.SSH: {
                        let branchName = branchController.getCurrentBranchName()
                        let remoteRes = remoteController.push("origin", branchName, false)
                        if (!remoteRes.success) {
                            if (notificationController)
                                notificationController.error(remoteRes.errorMessage || "Push failed", "Push Error", 5000)
                        } else {
                            if (notificationController)
                                notificationController.success("Changes pushed successfully", "Push", 3000)
                        }
                        break
                    }
                    case RepositoryController.GitProtocol.HTTPS:
                    case RepositoryController.GitProtocol.HTTP:
                        root.authPurpose = "push"
                        userAuthenticationPopup.open()
                        break
                    default:
                        if (notificationController)
                            notificationController.error("Unsupported protocol", "Push Error", 5000)
                    }
                }

                ToolTip.visible: pushBtnHeader.hovered
                ToolTip.text: "Push to origin"
                ToolTip.delay: 600
            }

            Item {
                Layout.fillWidth: true
            }

            ToolButton {
                id: fetchBtnHeader
                Layout.preferredWidth: headerRow.compact ? 26 : 72
                Layout.preferredHeight: 26
                hoverEnabled: true
                enabled: !root.isFetching
                opacity: root.isFetching ? 0.5 : 1.0

                text: Style.icons.download
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: 13

                contentItem: Item {
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: fetchBtnHeader.text
                            font: fetchBtnHeader.font
                            color: Style.colors.foreground
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Fetch"
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Style.colors.foreground
                            visible: !headerRow.compact
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                background: Rectangle {
                    radius: 5
                    color: !fetchBtnHeader.enabled ? Style.colors.primaryBackground :
                           fetchBtnHeader.down ? Style.colors.surfaceMuted :
                           fetchBtnHeader.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                onClicked: {
                        let remotesRes = remoteController.getRemotes()
                        if (!remotesRes.success || !remotesRes.data || remotesRes.data.length === 0) {
                            if (notificationController)
                                notificationController.error("No remotes configured", "Fetch", 5000)
                            return
                        }
                        let httpsRemotes = []
                        let sshFailed = []
                        root.isFetching = true
                        for (let i = 0; i < remotesRes.data.length; i++) {
                            let remote = remotesRes.data[i]
                            let urlRes = remoteController.getRemoteUrl(remote.name)
                            if (!urlRes.success) {
                                sshFailed.push({ name: remote.name, message: urlRes.errorMessage || "No URL" })
                                continue
                            }
                            let url = urlRes.data.url
                            let protocol = repositoryController.detectGitProtocol(url)
                            switch (protocol) {
                            case RepositoryController.GitProtocol.SSH: {
                                let res = remoteController.fetch(remote.name)
                                if (!res.success)
                                    sshFailed.push({ name: remote.name, message: res.errorMessage || "Fetch failed" })
                                break
                            }
                            case RepositoryController.GitProtocol.HTTPS:
                            case RepositoryController.GitProtocol.HTTP:
                                httpsRemotes.push(remote.name)
                                break
                            default:
                                sshFailed.push({ name: remote.name, message: "Unsupported protocol" })
                            }
                        }
                        if (sshFailed.length > 0 && notificationController)
                            notificationController.error(sshFailed.map(f => f.name + ": " + f.message).join("; "), "Fetch Error", 7000)
                        else if (httpsRemotes.length === 0 && notificationController)
                            notificationController.success("Fetched from all remotes", "Fetch", 5000)
                        if (httpsRemotes.length > 0) {
                            root.pendingFetchRemoteNames = httpsRemotes
                            root.authPurpose = "fetch"
                            userAuthenticationPopup.open()
                        } else {
                            root.isFetching = false
                        }
                        root.update()
                }

                ToolTip.visible: fetchBtnHeader.hovered
                ToolTip.text: root.isFetching ? "Fetching…" : "Fetch all remotes"
                ToolTip.delay: 600
            }

            ToolButton {
                id: pushForceBtnHeader
                Layout.preferredWidth: headerRow.compact ? 26 : 96
                Layout.preferredHeight: 26
                hoverEnabled: true

                text: Style.icons.arrowUp
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: 13

                contentItem: Item {
                    Row {
                        anchors.centerIn: parent
                        spacing: 5
                        Text {
                            text: pushForceBtnHeader.text
                            font: pushForceBtnHeader.font
                            color: Style.colors.foreground
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Text {
                            text: "Push Force"
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: Style.colors.foreground
                            visible: !headerRow.compact
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                background: Rectangle {
                    radius: 5
                    color: !pushForceBtnHeader.enabled ? Style.colors.primaryBackground :
                           pushForceBtnHeader.down ? Style.colors.surfaceMuted :
                           pushForceBtnHeader.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                onClicked: {
                    let res = remoteController.getRemoteUrl("origin")
                    if (!res.success) {
                        if (notificationController)
                            notificationController.error(res.errorMessage || "Failed to get remote URL", "Push Force Error", 5000)
                        return
                    }
                    let url = res.data.url
                    let protocol = repositoryController.detectGitProtocol(url)
                    switch (protocol) {
                    case RepositoryController.GitProtocol.SSH: {
                        let branchName = branchController.getCurrentBranchName()
                        let remoteRes = remoteController.push("origin", branchName, true)
                        if (!remoteRes.success) {
                            if (notificationController)
                                notificationController.error(remoteRes.errorMessage || "Push force failed", "Push Force Error", 5000)
                        } else {
                            if (notificationController)
                                notificationController.success("Changes force pushed successfully", "Push Force", 3000)
                        }
                        break
                    }
                    case RepositoryController.GitProtocol.HTTPS:
                    case RepositoryController.GitProtocol.HTTP:
                        root.authPurpose = "pushForce"
                        userAuthenticationPopup.open()
                        break
                    default:
                        if (notificationController)
                            notificationController.error("Unsupported protocol", "Push Force Error", 5000)
                    }
                }

                ToolTip.visible: pushForceBtnHeader.hovered
                ToolTip.text: "Force push to origin"
                ToolTip.delay: 600
            }
        }
    }

    onStatusControllerChanged: {
        update()
        branchController.getCurrentBranchName()
    }

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/

    Connections {
        target: repositoryController

        function onCurrentRepoChanged() {
            root.update()
            currentBranchNameText.text = branchController.getCurrentBranchName()
            commitPanelBranchText.text = branchController ? branchController.getCurrentBranchName() : ""
        }
    }

    Connections {
        target: remoteController

        function onFetchFinished(result) {
            if (!result || !result.remote)
                return

            const remoteName = result.remote
            root.activeFetchRemotes = root.activeFetchRemotes.filter(function(name) { return name !== remoteName })
            root.fetchBatchResults.push(result)

            if (notificationController) {
                if (result.success)
                    notificationController.success("Fetched from " + remoteName, "Fetch", 5000)
                else
                    notificationController.error("Fetch failed for " + remoteName + ": " + (result.errorMessage || "Unknown error"), "Fetch Error", 7000)
            }

            root.isFetching = root.activeFetchRemotes.length > 0 || root.pendingFetchRemoteNames.length > 0
            if (root.activeFetchRemotes.length === 0 && root.pendingFetchRemoteNames.length === 0 && root.fetchBatchResults.length > 0) {
                let popup = root.uiSessionPopups?.fetchSummaryPopup
                if (popup) {
                    popup.results = []
                    popup.results = root.fetchBatchResults
                    popup.open()
                }
            }
            root.update()
        }

        function onPullFinished(result) {
            if (root.authPurpose !== "pull_async_origin")
                return

            if (!result || result.remote !== "origin")
                return

            root.isFetching = false
            root.authPurpose = "push"

            if (result.success) {
                if (root.notificationController)
                    root.notificationController.success("Pull completed", "Pull", 3000)
                errorMessageLabel.text = ""
            } else {
                errorMessageLabel.text = result.errorMessage ?? "Pull error"
                if (root.notificationController)
                    root.notificationController.error(errorMessageLabel.text, "Pull Error", 5000)
            }

            root.update()
        }
    }

    Connections {
        target: root.uiSessionPopups ? root.uiSessionPopups.fetchSummaryPopup : null

        function onClosed() {
            root.fetchBatchResults = []
        }
    }

    Connections {
        target: userAuthenticationPopup

        function onPasswordConfirm(password){
            if (root.authPurpose === "pull") {
                let pullRes = remoteController.fetchWithToken("origin", password)
                if (!pullRes.success) {
                    if (root.notificationController)
                        root.notificationController.error(pullRes.errorMessage || "Pull failed", "Pull Error", 5000)
                } else {
                    if (root.notificationController)
                        root.notificationController.success("Pulled successfully", "Pull", 3000)
                    root.update()
                }
                root.authPurpose = "push"
                return
            }

            if (root.authPurpose === "fetch") {
                let failed = []
                for (let i = 0; i < root.pendingFetchRemoteNames.length; i++) {
                    let name = root.pendingFetchRemoteNames[i]
                    let res = root.remoteController.fetchWithToken(name, password)
                    if (res.success) {
                        if (root.activeFetchRemotes.indexOf(name) === -1)
                            root.activeFetchRemotes.push(name)
                    } else {
                        failed.push({ name: name, message: res.errorMessage || "Unknown error" })
                        root.fetchBatchResults.push({
                            remote: name,
                            success: false,
                            errorMessage: res.errorMessage || "Unknown error",
                            data: { timestamp: Qt.formatDateTime(new Date(), Qt.ISODate), status: "Fetch did not start" }
                        })
                    }
                }
                if (failed.length > 0 && root.notificationController) {
                    root.notificationController.error("Fetch failed for: " + failed.map(function(f){ return f.name + " (" + f.message + ")" }).join("; "), "Fetch Error", 7000)
                }
                root.isFetching = root.activeFetchRemotes.length > 0
                root.authPurpose = "push"
                root.pendingFetchRemoteNames = []
                root.pendingPullRemoteNames = []
                root.update()
                return
            }

            if (root.authPurpose === "pull") {
                let failed = []
                let succeeded = []
                for (let i = 0; i < root.pendingPullRemoteNames.length; i++) {
                    let name = root.pendingPullRemoteNames[i]
                    let res = root.remoteController.pull(name, "", password)
                    if (res.success)
                        succeeded.push(name)
                    else
                        failed.push({ name: name, message: res.errorMessage || "Unknown error" })
                }
                if (root.notificationController) {
                    if (failed.length === 0)
                        root.notificationController.success("Pulled from remotes: " + succeeded.join(", "), "Pull", 5000)
                    else if (succeeded.length === 0)
                        root.notificationController.error("Pull failed for: " + failed.map(f => f.name + " (" + f.message + ")").join("; "), "Pull Error", 7000)
                    else
                        root.notificationController.error("Pull partial failure: " + failed.map(f => f.name + " (" + f.message + ")").join("; "), "Pull Error", 7000)
                }
                root.isFetching = false
                root.authPurpose = "push"
                root.pendingFetchRemoteNames = []
                root.pendingPullRemoteNames = []
                root.update()
                return
            }

            if (root.authPurpose === "pull_async_origin") {
                let startRes = root.remoteController.pull("origin", "", password)
                if (!startRes.success) {
                    root.isFetching = false
                    root.authPurpose = "push"
                    errorMessageLabel.text = startRes.errorMessage ?? "Failed to start pull"
                    if (root.notificationController)
                        root.notificationController.error(errorMessageLabel.text, "Pull Error", 5000)
                    return
                }
                root.isFetching = true
                return
            }

            let branchName = branchController.getCurrentBranchName()
            if(branchName.length === 0){
                root.notificationController.error("Current branch name is invalid", "Branch Error", 5000)
                errorMessageLabel.text = "current Branch Name invalid!"
            }else{
                let isForce = root.authPurpose === "pushForce"
                let remoteRes = remoteController.push(
                    "origin",
                    branchName,
                    password,
                    isForce)

                if(!remoteRes.success){
                    root.notificationController.error(remoteRes.errorMessage || "Push failed", isForce ? "Push Force Error" : "Push Error", 5000)
                    errorMessageLabel.text = remoteRes.errorMessage ?? "push error"
                }else{
                    root.notificationController.success(isForce ? "Changes force pushed successfully" : "Changes pushed successfully", isForce ? "Push Force" : "Push", 3000)
                    commitTextArea.text = ""
                }
            }
            root.authPurpose = "push"

            root.update()
        }

        function onRejected() {
            if (root.authPurpose === "fetch" || root.authPurpose === "pull" || root.authPurpose === "pull_async_origin") {
                root.isFetching = root.activeFetchRemotes.length > 0
                root.isFetching = false
                root.authPurpose = "push"
                root.pendingFetchRemoteNames = []
                root.pendingPullRemoteNames = []
            }
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        anchors.topMargin: 8
        spacing: 8

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
                    Layout.preferredHeight: 140
                    color: Style.colors.secondaryBackground
                    radius: 2

                    ColumnLayout {
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
                                            let res = remoteController.getRemoteUrl("origin")
                                            if (!res.success) {
                                                if (notificationController)
                                                    notificationController.error(res.errorMessage || "Failed to get remote URL", "Push Force Error", 5000)
                                                return
                                            }
                                            let url = res.data.url
                                            let protocol = repositoryController.detectGitProtocol(url)
                                            switch (protocol) {
                                            case RepositoryController.GitProtocol.SSH: {
                                                let branchName = branchController.getCurrentBranchName()
                                                let remoteRes = remoteController.push("origin", branchName, true)
                                                if (!remoteRes.success) {
                                                    if (notificationController)
                                                        notificationController.error(remoteRes.errorMessage || "Push force failed", "Push Force Error", 5000)
                                                    errorMessageLabel.text = remoteRes.errorMessage ?? "push force error"
                                                } else {
                                                    if (notificationController)
                                                        notificationController.success("Changes force pushed successfully", "Push Force", 3000)
                                                }
                                                break
                                            }
                                            case RepositoryController.GitProtocol.HTTPS:
                                            case RepositoryController.GitProtocol.HTTP:
                                                root.authPurpose = "pushForce"
                                                userAuthenticationPopup.open()
                                                break
                                            default:
                                                if (notificationController)
                                                    notificationController.error("Unsupported protocol", "Push Force Error", 5000)
                                            }
                                            root.update()
                                        }
                                    },
                                    {
                                        text: "Fetch",
                                        icon: Style.icons.download,
                                        enabled: !root.isFetching,
                                        action: function() {
                                            let remotesRes = remoteController.getRemotes()
                                            if (!remotesRes.success || !remotesRes.data || remotesRes.data.length === 0) {
                                                if (notificationController)
                                                    notificationController.error("No remotes configured", "Fetch", 5000)
                                                return
                                            }
                                            root.fetchBatchResults = []
                                            let httpsRemotes = []
                                            let sshFailed = []
                                            root.activeFetchRemotes = []
                                            root.isFetching = true
                                            for (let i = 0; i < remotesRes.data.length; i++) {
                                                let remote = remotesRes.data[i]
                                                let urlRes = remoteController.getRemoteUrl(remote.name)
                                                if (!urlRes.success) {
                                                    sshFailed.push({ name: remote.name, message: urlRes.errorMessage || "No URL" })
                                                    continue
                                                }
                                                let url = urlRes.data.url
                                                let protocol = repositoryController.detectGitProtocol(url)
                                                switch (protocol) {
                                                case RepositoryController.GitProtocol.SSH: {
                                                    let res = remoteController.fetch(remote.name)
                                                    if (res.success) {
                                                        if (root.activeFetchRemotes.indexOf(remote.name) === -1)
                                                            root.activeFetchRemotes.push(remote.name)
                                                    } else {
                                                        let msg = res.errorMessage || "Fetch failed"
                                                        sshFailed.push({ name: remote.name, message: msg })
                                                        root.fetchBatchResults.push({
                                                            remote: remote.name,
                                                            success: false,
                                                            errorMessage: msg,
                                                            data: { timestamp: Qt.formatDateTime(new Date(), Qt.ISODate), status: "Fetch did not start" }
                                                        })
                                                    }
                                                    break
                                                }
                                                case RepositoryController.GitProtocol.HTTPS:
                                                case RepositoryController.GitProtocol.HTTP:
                                                    httpsRemotes.push(remote.name)
                                                    break
                                                default:
                                                    sshFailed.push({ name: remote.name, message: "Unsupported protocol" })
                                                }
                                            }
                                            if (sshFailed.length > 0 && notificationController) {
                                                let msg = sshFailed.map(f => f.name + ": " + f.message).join("; ")
                                                notificationController.error(msg, "Fetch Error", 7000)
                                            }
                                            if (httpsRemotes.length > 0) {
                                                root.pendingFetchRemoteNames = httpsRemotes
                                                root.authPurpose = "fetch"
                                                userAuthenticationPopup.open()
                                            }
                                            if (httpsRemotes.length === 0 && root.activeFetchRemotes.length === 0)
                                                root.isFetching = false
                                            root.update()
                                        }
                                    },
                                    {
                                        text: "Pull",
                                        icon: Style.icons.arrowDown,
                                        enabled: !root.isFetching,
                                        action: function() {
                                            let remotesRes = remoteController.getRemotes()
                                            if (!remotesRes.success || !remotesRes.data || remotesRes.data.length === 0) {
                                                if (notificationController)
                                                    notificationController.error("No remotes configured", "Pull", 5000)
                                                return
                                            }
                                            let httpsRemotes = []
                                            let pullFailed = []
                                            root.isFetching = true
                                            for (let i = 0; i < remotesRes.data.length; i++) {
                                                let remote = remotesRes.data[i]
                                                let urlRes = remoteController.getRemoteUrl(remote.name)
                                                if (!urlRes.success) {
                                                    pullFailed.push({ name: remote.name, message: urlRes.errorMessage || "No URL" })
                                                    continue
                                                }
                                                let url = urlRes.data.url
                                                let protocol = repositoryController.detectGitProtocol(url)
                                                switch (protocol) {
                                                case RepositoryController.GitProtocol.SSH: {
                                                    let res = remoteController.pull(remote.name)
                                                    if (!res.success)
                                                        pullFailed.push({ name: remote.name, message: res.errorMessage || "Pull failed" })
                                                    break
                                                }
                                                case RepositoryController.GitProtocol.HTTPS:
                                                case RepositoryController.GitProtocol.HTTP:
                                                    httpsRemotes.push(remote.name)
                                                    break
                                                default:
                                                    pullFailed.push({ name: remote.name, message: "Unsupported protocol" })
                                                }
                                            }
                                            if (pullFailed.length > 0 && notificationController) {
                                                let msg = pullFailed.map(f => f.name + ": " + f.message).join("; ")
                                                notificationController.error(msg, "Pull Error", 7000)
                                            } else if (httpsRemotes.length === 0 && notificationController) {
                                                notificationController.success("Pulled from remotes", "Pull", 5000)
                                            }
                                            if (httpsRemotes.length > 0) {
                                                root.pendingPullRemoteNames = httpsRemotes
                                                root.authPurpose = "pull"
                                                userAuthenticationPopup.open()
                                            } else {
                                                root.isFetching = false
                                            }
                                            root.update()
                                        }
                                    }
                                ]
                        }

                        ModernInputArea {
                            id: commitTextArea

                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            placeholder: "What did you change?..."
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 6

                            readonly property bool commitEnabled: changesFileLists.stagedModel.length > 0 && commitTextArea.text !== ""

                            Rectangle {
                                id: commitBtn
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                radius: 4
                                color: parent.commitEnabled ? Style.colors.accent : Style.colors.disabledButton

                                MouseArea {
                                    id: commitBtnMouse
                                    anchors.left: parent.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: parent.width - 29
                                    hoverEnabled: true
                                    cursorShape: parent.parent.commitEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    enabled: parent.parent.commitEnabled

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 4
                                        color: commitBtnMouse.containsMouse ? Qt.rgba(0,0,0,0.12) : "transparent"
                                    }

                                    Text {
                                        id: commitBtnLabel
                                        anchors.centerIn: parent
                                        text: "Commit"
                                        color: Style.colors.secondaryForeground
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 12
                                    }

                                    onClicked: {
                                        let res = commitController.commit(commitTextArea.text, false, false)
                                        if (res.success) {
                                            commitTextArea.text = ""
                                            root.notificationController.success("Commit successful", "Commit", 3000)
                                        } else {
                                            root.notificationController.error(res.errorMessage || "Commit failed", "Commit Error", 5000)
                                            errorMessageLabel.text = res.errorMessage ?? "commit error"
                                        }
                                        root.update()
                                    }
                                }

                                Rectangle {
                                    id: caretDivider
                                    anchors.right: commitCaretZone.left
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    anchors.topMargin: 7
                                    anchors.bottomMargin: 7
                                    width: 1
                                    color: Style.colors.secondaryForeground
                                    opacity: 0.35
                                }

                                MouseArea {
                                    id: commitCaretZone
                                    anchors.right: parent.right
                                    anchors.top: parent.top
                                    anchors.bottom: parent.bottom
                                    width: 28
                                    hoverEnabled: true
                                    cursorShape: parent.parent.commitEnabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    enabled: parent.parent.commitEnabled

                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 4
                                        color: commitCaretZone.containsMouse ? Qt.rgba(0,0,0,0.12) : "transparent"
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        text: Style.icons.caretDown
                                        font.family: Style.fontTypes.font6ProSolid
                                        font.pixelSize: 11
                                        color: Style.colors.secondaryForeground
                                    }

                                    onClicked: {
                                        var pos = commitCaretZone.mapToItem(commitPanel, 0, commitBtn.height)
                                        commitDropMenu.x = Math.min(pos.x, commitPanel.width - commitDropMenu.implicitWidth - 48)
                                        commitDropMenu.y = pos.y + 4
                                        commitDropMenu.open()
                                    }
                                }

                                ContextMenu {
                                    id: commitDropMenu
                                    parent: commitPanel
                                    menuModel: [
                                        {
                                            text: "Commit Amend",
                                            icon: Style.icons.penToSquare,
                                            action: function() {
                                                let res = commitController.commit(commitTextArea.text, true, false)
                                                if (res.success) {
                                                    commitTextArea.text = ""
                                                    root.notificationController.success("Commit amended successfully", "Commit Amend", 3000)
                                                } else {
                                                    root.notificationController.error(res.errorMessage || "Amend failed", "Commit Amend Error", 5000)
                                                    errorMessageLabel.text = res.errorMessage ?? "amend error"
                                                }
                                                root.update()
                                            }
                                        },
                                        {
                                            text: "Commit && Push",
                                            icon: Style.icons.arrowUp,
                                            action: function() {
                                                let commitRes = commitController.commit(commitTextArea.text, false, false)
                                                if (!commitRes.success) {
                                                    root.notificationController.error(commitRes.errorMessage || "Commit failed", "Commit Error", 5000)
                                                    errorMessageLabel.text = commitRes.errorMessage ?? "commit error"
                                                    return
                                                }
                                                commitTextArea.text = ""
                                                root.notificationController.success("Commit successful", "Commit", 3000)
                                                root.update()
                                                let urlRes = remoteController.getRemoteUrl("origin")
                                                if (!urlRes.success) {
                                                    root.notificationController.error(urlRes.errorMessage || "Failed to get remote URL", "Push Error", 5000)
                                                    return
                                                }
                                                let protocol = repositoryController.detectGitProtocol(urlRes.data.url)
                                                switch (protocol) {
                                                case RepositoryController.GitProtocol.SSH: {
                                                    let branchName = branchController.getCurrentBranchName()
                                                    let pushRes = remoteController.push("origin", branchName, false)
                                                    if (!pushRes.success) {
                                                        root.notificationController.error(pushRes.errorMessage || "Push failed", "Push Error", 5000)
                                                        errorMessageLabel.text = pushRes.errorMessage ?? "push error"
                                                    } else {
                                                        root.notificationController.success("Changes pushed successfully", "Push", 3000)
                                                    }
                                                    break
                                                }
                                                case RepositoryController.GitProtocol.HTTPS:
                                                case RepositoryController.GitProtocol.HTTP:
                                                    root.authPurpose = "push"
                                                    userAuthenticationPopup.open()
                                                    break
                                                default:
                                                    root.notificationController.error("Unsupported protocol", "Push Error", 5000)
                                                }
                                                root.update()
                                            }
                                        }
                                    ]
                                }
                            }

                            Rectangle {
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                radius: 4
                                color: commitOptionsDotMouse.containsMouse ? Style.colors.cardBackground : Style.colors.secondaryBackground
                                border.color: Style.colors.primaryBorder
                                border.width: 1

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u22EE"
                                    font.pixelSize: 16
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
                            font.family: Style.fontTypes.roboto
                            font.pixelSize: 10
                            wrapMode: TextEdit.Wrap
                        }
                    }
                }

                // File lists
                Rectangle {
                    id: fileListsPanel
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"

                    // Default fake data so the UI is visibly populated without git wiring.
                    // Keep one list non-empty and the other empty to demonstrate both states.
                    property var unstagedChanges: []

                    property var stagedChanges: []

                    ChangesFileLists {
                        id: changesFileLists
                        anchors.fill: parent
                        unstagedModel: fileListsPanel.unstagedChanges
                        stagedModel: fileListsPanel.stagedChanges

                        selectedFilePath: root.selectedFilePath

                        onFileSelected: function(filePath) {
                            root.selectedFilePath = filePath
                            let isStaged = fileListsPanel.stagedChanges.some(file => file.path === filePath)
                            root.updateDiff(isStaged)
                        }

                        onStageFileRequested: function(filePath) {
                            let res = statusController.stageFile(filePath)
                            if (!res.success) {
                                root.notificationController.error(res.errorMessage || "Failed to stage file", "Stage Error", 5000)
                            }
                            root.update()
                        }

                        onUnstageFileRequested: function(filePath) {
                            let res = statusController.unstageFile(filePath)
                            if (!res.success) {
                                root.notificationController.error(res.errorMessage || "Failed to unstage file", "Unstage Error", 5000)
                            }
                            root.update()
                        }

                        onDiscardFileRequested: function(filePath) {
                            let res = statusController.revertFile(filePath)
                            if (res.success) {
                                root.notificationController.success("File changes discarded successfully", "Discard", 3000)
                            } else {
                                root.notificationController.error(res.errorMessage || "Failed to discard file changes", "Discard Error", 5000)
                            }
                            root.update()
                        }

                        onOpenFileRequested: function(filePath, isStaged) {
                            root.selectedFilePath = filePath;
                            updateDiff(isStaged)
                        }

                        onStageAllRequested: function() {
                            let res = statusController.stageAll()
                            if (res.success) {
                                root.notificationController.success("All files staged successfully", "Stage All", 3000)
                            } else {
                                root.notificationController.error(res.errorMessage || "Failed to stage all files", "Stage Error", 5000)
                            }
                            root.update()
                        }

                        onUnstageAllRequested: function() {
                            let failedFiles = []
                            fileListsPanel.stagedChanges.forEach((file)=>{
                                let res = statusController.unstageFile(file.path)
                                if (!res.success) {
                                    failedFiles.push(file.path)
                                }
                            })
                            if (failedFiles.length > 0) {
                                root.notificationController.error("Failed to unstage some files", "Unstage Error", 5000)
                            } else if (fileListsPanel.stagedChanges.length > 0) {
                                root.notificationController.success("All files unstaged successfully", "Unstage All", 3000)
                            }
                            root.update()
                        }

                        onDiscardAllRequested: function() {
                            let res = statusController.revertAll()
                            if (res.success) {
                                root.notificationController.success("All changes discarded successfully", "Discard All", 3000)
                            } else {
                                root.notificationController.error(res.errorMessage || "Failed to discard all changes", "Discard Error", 5000)
                            }
                            root.update()
                        }

                        onStashAllRequested: function(section) {
                            let message = section === "unstaged" ? "Stash unstaged changes" : "Stash staged changes";
                            let keepIndex = section === "staged";
                            let result = stashController.save(message, keepIndex);

                            if (result.success) {
                                root.notificationController.success("Changes stashed successfully", "Stash", 3000)
                                root.update();
                            } else {
                                root.notificationController.error(result.errorMessage || "Stash failed", "Stash Error", 5000)
                                errorMessageLabel.text = result.errorMessage ?? "Stash failed";
                            }
                        }
                    }
                }
            }
        }

        DiffView {
            id: diffView
            Layout.fillHeight: true
            Layout.fillWidth: true
            chunkMode: true
            contextLines: 0
            expandLines: 10
            onRequestStage: function (start, end, type) {
                let res = root.statusController.stageSelectedLines(root.selectedFilePath, start, end, type)
                if (res.success) {
                    root.notificationController.success("Selected lines staged", "Stage", 2000)
                } else {
                    root.notificationController.error(res.errorMessage || "Failed to stage selected lines", "Stage Error", 5000)
                }
                root.update()
            }

            onRequestRevert: function (start, end, type) {
                let res = root.statusController.revertSelectedLines(root.selectedFilePath, start, end, type)
                if (res.success) {
                    root.notificationController.success("Selected lines reverted", "Revert", 2000)
                } else {
                    root.notificationController.error(res.errorMessage || "Failed to revert selected lines", "Revert Error", 5000)
                }
                root.update()
            }
        }
    }

    function updateDiff(isStaged) {
        let oldY = diffView.scrollPosition;

        if(diffView.chunkMode){
            let res = root.statusController.getChunkedDiffView(root.selectedFilePath, isStaged)
            if (res.success) {
                diffView.chunkData = res.data.chunks
            }
        }else{
            let res = root.statusController.getDiffView(root.selectedFilePath, isStaged)
            if (res.success) {
                diffView.diffData = res.data.lines
            }
        }

        diffView.readOnly = isStaged

        Qt.callLater(() => {
            diffView.scrollPosition = oldY;
        });
    }

    function updateStatus() {
        let res = statusController.status()

        if (!res.success) return;

        fileListsPanel.unstagedChanges = []
        fileListsPanel.stagedChanges = []

        res.data.forEach((file) => {
            if (file.isStaged) {
                fileListsPanel.stagedChanges.push(file)
            }
            if (file.isUnstaged || file.isUntracked) {
                fileListsPanel.unstagedChanges.push(file)
            }
        })

        fileListsPanel.unstagedChanges = fileListsPanel.unstagedChanges.slice(0)
        fileListsPanel.stagedChanges = fileListsPanel.stagedChanges.slice(0)

        let totalFiles = fileListsPanel.stagedChanges.length + fileListsPanel.unstagedChanges.length;

        if (totalFiles === 1 && root.selectedFilePath === "") {
            let firstFile = fileListsPanel.unstagedChanges.length > 0
                            ? fileListsPanel.unstagedChanges[0]
                            : fileListsPanel.stagedChanges[0];

            root.selectedFilePath = firstFile.path;
            diffView.readOnly = firstFile.isStaged && !firstFile.isUnstaged;
        }
    }

    function update() {
        updateStatus()
        updateDiff(diffView.readOnly)
    }
}
