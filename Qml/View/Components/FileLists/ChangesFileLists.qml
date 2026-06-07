import QtQuick
import QtQuick.Layouts

import GitEase
/*! ***********************************************************************************************
 * ChangesFileLists
 * Two stacked file lists used in Committing page:
 *   - Staged Changes (top)
 *   - Unstaged Changes (bottom)
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property StatusController        statusController:        null
    property NotificationController  notificationController:  null
    property StashController         stashController:         null

    property var unstagedModel: []
    property var stagedModel: []
    property bool hasUnsavedChanges: false
    property string currentFile: ""
    property var fileBuffer: []
    property var showSaveDialog

    /* Signals
     * ****************************************************************************************/
    signal fileSelected(string filePath, bool isStaged)
    signal changesSaved()

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 1
    implicitHeight: 1

    onCurrentFileChanged: {
        //unstagedSection.selectedFilePath = root.currentFile
    }

    Component.onCompleted: Qt.callLater(function() {root.updateStatus()})

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        StagedFileListSection {
            id: stagedSection
            Layout.fillWidth: true
            Layout.fillHeight: wantsFillHeight
            Layout.minimumHeight: 32
            Layout.preferredHeight: expanded ? -1 : 32

            model: root.stagedModel

            onUnstageFileRequested: function(filePath) {
                root.showSaveDialog(
                            () => {
                                let res = statusController.unstageFile(filePath)
                                if (!res.success) {
                                    root.notificationController.error(res.errorMessage || "Failed to unstage file", "Unstage Error", 5000)
                                }
                                root.updateStatus()
                            }
                )
            }

            onOpenFileRequested: function(filePath) {
                root.fileSelected(filePath, true)
            }

            onUnstageAllRequested: function() {
                root.showSaveDialog(
                            () => {
                                let failedFiles = []
                                root.stagedModel.forEach((file)=>{
                                    let res = statusController.unstageFile(file.path)
                                    if (!res.success) {
                                        failedFiles.push(file.path)
                                    }
                                })
                                if (failedFiles.length > 0) {
                                    root.notificationController.error("Failed to unstage some files", "Unstage Error", 5000)
                                } else if (root.unstagedModel.length > 0) {
                                    root.notificationController.success("All files unstaged successfully", "Unstage All", 3000)
                                }
                                root.updateStatus()
                            }
                )
            }

            onStashAllRequested: function() {
                root.showSaveDialog(
                            () => {
                                let message = "Stash staged changes";
                                let result = stashController.save(message, true);

                                if (result.success) {
                                    root.notificationController.success("Changes stashed successfully", "Stash", 3000)
                                    root.updateStatus();
                                } else {
                                    root.notificationController.error(result.errorMessage || "Stash failed", "Stash Error", 5000)
                                    errorMessageLabel.text = result.errorMessage ?? "Stash failed";
                                }
                            }
                )
            }

            onFileSelected: function(filePath) {
                unstagedSection.selectedFilePath = ""
                root.fileSelected(filePath, true)
            }
        }

        UnstagedFileListSection {
            id: unstagedSection
            Layout.fillWidth: true
            Layout.fillHeight: wantsFillHeight
            Layout.minimumHeight: 32
            Layout.preferredHeight: expanded ? -1 : 32

            model: root.unstagedModel

            onStageFileRequested: function(filePath) {
                root.showSaveDialog(
                            () => {
                                let res = statusController.stageFile(filePath)
                                if (!res.success) {
                                    root.notificationController.error(res.errorMessage || "Failed to stage file", "Stage Error", 5000)
                                }
                                root.updateStatus()
                            }
                )
            }

            onStashFileRequested: function(filePath) {
                let message = "Stashing file: " + filePath
                let res = stashController.stashFile(filePath, message)
                if (res.success) {
                    root.notificationController.success("File stashed: " + filePath, "Stash File", 3000)
                } else {
                    root.notificationController.error(res.errorMessage || "Failed to stash file", "Stash Error", 5000)
                }
                root.updateStatus()
            }

            onDiscardFileRequested: function(filePath) {
                function discardFile() {
                    let res = statusController.revertFile(filePath)
                    if (res.success) {
                        root.notificationController.success("File changes discarded successfully", "Discard", 3000)
                    } else {
                        root.notificationController.error(res.errorMessage || "Failed to discard file changes", "Discard Error", 5000)
                    }
                    root.updateStatus()
                }

                if(root.currentFile === filePath)
                {
                    root.changesSaved()
                    discardFile()
                    return
                }

                root.showSaveDialog(
                            () => {
                                discardFile()
                            }
                )
            }

            onOpenFileRequested: function(filePath) {
                root.showSaveDialog(
                            () => {
                                root.fileSelected(filePath, false)
                            }
                )
            }

            onStageAllRequested: function() {
                root.showSaveDialog(
                            () => {
                                let res = statusController.stageAll()
                                if (res.success) {
                                    root.notificationController.success("All files staged successfully", "Stage All", 3000)
                                } else {
                                    root.notificationController.error(res.errorMessage || "Failed to stage all files", "Stage Error", 5000)
                                }
                                root.updateStatus()
                            }
                )
            }

            onDiscardAllRequested: function() {
                let res = statusController.revertAll()
                if (res.success) {
                    root.notificationController.success("All changes discarded successfully", "Discard All", 3000)
                } else {
                    root.notificationController.error(res.errorMessage || "Failed to discard all changes", "Discard Error", 5000)
                }
                root.updateStatus()
            }

            onStashAllRequested: function() {
                root.showSaveDialog(
                            () => {
                                let message = "Stash unstaged changes"
                                let result = stashController.save(message, false);

                                if (result.success) {
                                    root.notificationController.success("Changes stashed successfully", "Stash", 3000)
                                    root.updateStatus();
                                } else {
                                    root.notificationController.error(result.errorMessage || "Stash failed", "Stash Error", 5000)
                                    errorMessageLabel.text = result.errorMessage ?? "Stash failed";
                                }
                            }
                )
            }

            onFileSelected: function(filePath) {
                stagedSection.selectedFilePath = ""
                root.fileSelected(filePath, false)
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: !(stagedSection.wantsFillHeight && unstagedSection.wantsFillHeight)
            Layout.preferredHeight: 0
            visible: true
        }
    }

    /* Functions
     * ****************************************************************************************/
    function updateStatus() {
        let res = root.statusController.status()

        if (!res.success)
            return;

        root.unstagedModel = []
        root.stagedModel = []

        res.data.forEach((file) => {
            if (file.isStaged) {
                root.stagedModel.push(file)
            }
            if (file.isUnstaged || file.isUntracked) {
                root.unstagedModel.push(file)
            }
        })

        root.unstagedModel = root.unstagedModel.slice(0)
        root.stagedModel = root.stagedModel.slice(0)

        let path = ""
        let isStaged = false

        if (root.unstagedModel.length > 0) {
            path = root.unstagedModel[0].path
        } else if (root.stagedModel.length > 0) {
            isStaged = true
            path = root.stagedModel[0].path
        }

        unstagedSection.selectedFilePath = isStaged ? "" : path
        stagedSection.selectedFilePath = isStaged ? path : ""

        root.fileSelected(path, isStaged)
    }
}
