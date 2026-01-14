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
    property var                  page:                 null

    property RepositoryController repositoryController: null

    property StatusController     statusController:     null

    property string               selectedFilePath:     ""

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
        anchors.margins: 8
        anchors.topMargin: 32
        spacing: 12

        // Left panel: two stacked placeholders
        Rectangle {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.preferredWidth: root.width / 3
            color: "transparent"

            ColumnLayout {
                anchors.fill: parent
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: "(commit actions) (placeholder)"
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 13
                        color: Style.colors.placeholderText
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
                        }

                        // TODO :: only for show demo and handlers
                        onStageFileRequested: function(filePath) {
                            statusController.stageFile(filePath)
                            root.update()
                        }

                        onUnstageFileRequested: function(filePath) {

                            //TODO Not rest head
                            statusController.unstageFile(filePath)
                            root.update()
                        }

                        onDiscardFileRequested: function(filePath) {
                            const src = fileListsPanel.unstagedChanges
                            const idx = src.findIndex(function(it) { return it.path === filePath })
                            if (idx < 0)
                                return

                            fileListsPanel.unstagedChanges = src.slice(0, idx).concat(src.slice(idx + 1))

                            if (root.selectedFilePath === filePath)
                                root.selectedFilePath = ""
                        }

                        onOpenFileRequested: function(filePath) {
                            console.log("Open file (placeholder):", filePath)

                            root.selectedFilePath = filePath;

                            let res = root.statusController.getDiffView(filePath)
                            if (res.success) {
                                diffView.diffData = res.data.lines
                            }
                        }

                        onStageAllRequested: function() {


                            statusController.stageAll()
                            root.update()
                        }

                        onUnstageAllRequested: function() {


                            statusController.unstageAll()
                            root.update()
                        }

                        onDiscardAllRequested: function() {
                            fileListsPanel.unstagedChanges = []
                            if (root.selectedFilePath !== "" && root.selectedFilePath !== null)
                                root.selectedFilePath = ""
                        }

                        onStashAllRequested: function(section) {
                            if (section === "unstaged") {
                                fileListsPanel.unstagedChanges = []
                            } else if (section === "staged") {
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
            Layout.preferredWidth: root.width * 2 / 3
            color: "transparent"

            DiffView {
                id: diffView
                anchors.fill: parent
            }
        }
    }


    function update() {
        let res = statusController.status()

        if (!res.success)
            return;
        fileListsPanel.unstagedChanges = []
        fileListsPanel.stagedChanges = []

        res.data.forEach((file)=>{
            if (file.isStaged) {
                fileListsPanel.stagedChanges.push(file)
            } else if (file.isUnstaged) {
                fileListsPanel.unstagedChanges.push(file)
            }
        })

        fileListsPanel.unstagedChanges = fileListsPanel.unstagedChanges.slice(0)
        fileListsPanel.stagedChanges = fileListsPanel.stagedChanges.slice(0)
    }
}
