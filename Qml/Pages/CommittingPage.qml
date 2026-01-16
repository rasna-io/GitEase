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
    property var                   page:                  null

    property RepositoryController  repositoryController:  null

    property StatusController      statusController:      null

    property BranchController      branchController:      null

    property CommitController      commitController:      null

    property RemoteController      remoteController:      null

    property UserProfileController userProfileController: null

    property string                selectedFilePath:      ""

    property var                   actionResult:          ({})

    onStatusControllerChanged: {
        update()
    }

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/
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
                                color: Style.colors.surfaceMuted
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
                                id: commitPushBtn
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
                                    onClicked: {
                                        // statusController.commit(commitTextArea.text)
                                        // repositoryController.push()
                                        commitTextArea.text = ""
                                        root.update()
                                    }
                                }
                            }

                            Rectangle {
                                id: commitOnlyBtn
                                Layout.preferredWidth: 30
                                Layout.preferredHeight: 30
                                color: Style.colors.primaryBackground
                                radius: 4
                                border.color: Style.colors.accent

                                Text {
                                    anchors.centerIn: parent
                                    font.family: Style.fontTypes.font6Pro
                                    text: Style.icons.arrowUp
                                    color: Style.colors.accent
                                    font.pixelSize: 16
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: {
                                        // statusController.commit(commitTextArea.text)
                                        commitTextArea.text = ""
                                        root.update()
                                    }
                                }
                            }

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
                            root.updateDiff()
                        }

                        onStageFileRequested: function(filePath) {
                            statusController.stageFile(filePath)
                            root.update()
                        }

                        onUnstageFileRequested: function(filePath) {
                            statusController.unstageFile(filePath)
                            root.update()
                        }

                        onDiscardFileRequested: function(filePath) {
                            statusController.revertFile(filePath)
                            root.update()
                        }

                        onOpenFileRequested: function(filePath) {
                            root.selectedFilePath = filePath;
                            updateDiff()
                        }

                        onStageAllRequested: function() {
                            statusController.stageAll()
                            root.update()
                        }

                        onUnstageAllRequested: function() {

                            fileListsPanel.stagedChanges.forEach((file)=>{
                                statusController.unstageFile(file.path)
                            })
                            root.update()
                        }

                        onDiscardAllRequested: function() {
                            statusController.revertAll()
                            root.update()
                        }

                        onStashAllRequested: function(section) {
                            if (section === "unstaged") {
                                fileListsPanel.unstagedChanges = []
                            }

                            if (section === "staged") {
                                fileListsPanel.stagedChanges = []
                            }

                            if (root.selectedFilePath !== "" && root.selectedFilePath !== null)
                                root.selectedFilePath = ""
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
                    root.statusController.stageSelectedLines(root.selectedFilePath, start, end, type)
                    root.update()
                }

                onRequestRevert: function (start, end, type) {
                    root.statusController.revertSelectedLines(root.selectedFilePath, start, end, type)
                    root.update()
                }
            }
        }
    }

    function updateDiff() {
        let res = root.statusController.getDiffView(root.selectedFilePath)
        if (res.success) {
            diffView.diffData = res.data.lines
        }
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
        updateDiff()
    }
}
