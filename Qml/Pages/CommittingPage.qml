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

    property string                  selectedFilePath:        ""

    property var                     actionResult:            ({})

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
        }
    }

    Connections {
        target: userAuthenticationPopup

        function onPasswordConfirm(password){
            let branchName = branchController.getCurrentBranchName()
            if(branchName.length === 0){
                root.notificationController.error("Current branch name is invalid", "Branch Error", 5000)
                errorMessageLabel.text = "current Branch Name invalid!"
            }else{
               let remoteRes = remoteController.push(
                    "origin",
                    branchName,
                    userProfileController.currentUserProfile.username,
                    password)

                if(!remoteRes.success){
                    root.notificationController.error(remoteRes.errorMessage || "Push failed", "Push Error", 5000)
                    errorMessageLabel.text = remoteRes.errorMessage ?? "push error"
                }else{
                    root.notificationController.success("Changes pushed successfully", "Push", 3000)
                    commitTextArea.text = ""
                }
            }

            root.update()
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 5
        anchors.topMargin: 5
        spacing: 12

        // Left panel: two stacked placeholders
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 330
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                Rectangle {
                    id: commitPanel
                    Layout.fillWidth: true
                    Layout.preferredHeight: 260
                    color: Style.colors.secondaryBackground
                    radius: 2

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 16
                        spacing: 12

                        // Header Section
                        RowLayout {
                            Layout.fillWidth: true

                            Text {
                                text: "COMMIT"
                                font.family: Style.fontTypes.roboto
                                font.pixelSize: 12
                                color: Style.colors.secondaryText
                            }

                            Item { Layout.fillWidth: true }

                            // RowLayout {
                            //     spacing: 6
                            //     Text {
                            //         text: "Amend"
                            //         font.pixelSize: 11
                            //         color: Style.colors.secondaryText
                            //     }
                            // }
                        }

                        // Modern Input Area
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            color: Style.colors.primaryBackground
                            radius: 6
                            border.width: 1
                            border.color: commitTextArea.activeFocus ? Style.colors.accent : Style.colors.primaryBorder

                            ColumnLayout {
                                anchors.fill: parent
                                spacing: 0

                                ScrollView {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    clip: true

                                    TextArea {
                                        id: commitTextArea
                                        placeholderText: "What did you change?..."
                                        placeholderTextColor: Style.colors.placeholderText
                                        color: Style.colors.foreground
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 14
                                        wrapMode: TextEdit.Wrap
                                        leftPadding: 12;
                                        topPadding: 12;
                                        rightPadding: 12
                                        selectByMouse: true
                                        background: null
                                        selectionColor: Style.colors.accent
                                        selectedTextColor: Style.colors.secondaryForeground
                                        Material.accent: Style.colors.accent
                                    }
                                }

                                // Character Count & Branch Hint
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 24
                                    color: "transparent"

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 12; anchors.rightMargin: 12
                                        Text {
                                            text: Style.icons.branch
                                            font.family: Style.fontTypes.font6Pro
                                            font.pixelSize: 10
                                            color: Style.colors.placeholderText
                                        }
                                        Text {
                                            id: currentBranchNameText
                                            text: branchController.getCurrentBranchName()
                                            font.family: Style.fontTypes.roboto
                                            font.pixelSize: 10
                                            color: Style.colors.placeholderText
                                        }
                                        Item { Layout.fillWidth: true }
                                        Text {
                                            text: commitTextArea.text.length + " characters"
                                            font.pixelSize: 10
                                            color: Style.colors.placeholderText
                                        }
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            Rectangle {
                                id: commitBtn
                                Layout.fillWidth: true
                                Layout.preferredHeight: 30
                                color: (changesFileLists.stagedModel.length > 0 && commitTextArea.text !== "")
                                        ? Style.colors.accent : Style.colors.disabledButton
                                radius: 1


                                Text {
                                    anchors.centerIn: parent
                                    text: "Commit"
                                    color: Style.colors.secondaryForeground
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 12
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    enabled: (changesFileLists.stagedModel.length > 0 && commitTextArea.text !== "")
                                    onClicked: {
                                        let res = commitController.commit(commitTextArea.text, false, false)

                                        if(res.success){
                                            commitTextArea.text = ""
                                            root.notificationController.success("Commit successful", "Commit", 3000)
                                        }else{
                                            root.notificationController.error(res.errorMessage || "Commit failed", "Commit Error", 5000)
                                            errorMessageLabel.text = res.errorMessage ?? "commit error"
                                        }

                                        root.update()
                                    }
                                }
                            }

                            Rectangle {
                                id: pushBtn
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                color: Style.colors.primaryBackground
                                radius: 4
                                border.color: Style.colors.foreground

                                Text {
                                    anchors.centerIn: parent
                                    font.family: Style.fontTypes.font6Pro
                                    text: Style.icons.arrowUp
                                    color: Style.colors.foreground
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        let res = remoteController.getRemoteUrl("origin")

                                        if (!res.success) {
                                            errorMessageLabel.text = res.errorMessage ?? "Failed to get remote URL"
                                            return
                                        }

                                        let url = res.data.url
                                        let protocol = repositoryController.detectGitProtocol(url)

                                        switch(protocol) {
                                        case RepositoryController.GitProtocol.SSH: {
                                            let branchName = branchController.getCurrentBranchName()
                                            let remoteRes = remoteController.push("origin", branchName, false)
                                            if (!remoteRes.success) {
                                                errorMessageLabel.text = remoteRes.errorMessage ?? "Push error"
                                            } else {
                                                commitTextArea.text = ""
                                            }
                                        }
                                        break;

                                        case RepositoryController.GitProtocol.HTTPS:
                                        case RepositoryController.GitProtocol.HTTP:
                                            userAuthenticationPopup.open()
                                            break;
                                        }
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

        // Right panel: diff placeholder
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: "transparent"

            DiffView {
                id: diffView
                anchors.fill: parent
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
    }

    function updateDiff(isStaged) {
        let oldY = diffView.scrollPosition;

        let res = root.statusController.getDiffView(root.selectedFilePath, isStaged)
        if (res.success) {
            diffView.diffData = res.data.lines
        }

        diffView.readOnly = isStaged

        Qt.callLater(() => {
            diffView.scrollPosition = oldY;
        });
    }

    function updateStatus() {
        let res = statusController.status()

        if (!res.success)
            return;
        fileListsPanel.unstagedChanges = []
        fileListsPanel.stagedChanges = []

        res.data.forEach((file)=>{
            if (file.isStaged) {
                fileListsPanel.stagedChanges.push(file)
            }
            if (file.isUnstaged || file.isUntracked) {
                fileListsPanel.unstagedChanges.push(file)
            }
        })

        fileListsPanel.unstagedChanges = fileListsPanel.unstagedChanges.slice(0)
        fileListsPanel.stagedChanges = fileListsPanel.stagedChanges.slice(0)
    }

    function update() {
        updateStatus()
        updateDiff(diffView.readOnly)
    }
}
