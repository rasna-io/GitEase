import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * GraphViewPage
 * Graph View Page shown Commit Graph Dock, File Changes and Diff View
 * ************************************************************************************************/

Item {
    id: root
    anchors.fill: parent

    // Provided by MainWindow Loader (current Page model)
    property var page: null

    // Provided by MainWindow Loader (UiSession context)
    property AppModel appModel: null

    property BranchController branchController: null

    property CommitController commitController: null

    property StatusController statusController: null

    property RepositoryController repositoryController: null
    readonly property var currentRepo: repositoryController?.appModel?.currentRepository ?? null

    property string selectedCommit: ""
    property string selectedFilePath: ""

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: commitGraphDock
            Layout.fillWidth: true
            Layout.minimumHeight: root.height / 2
            Layout.maximumHeight: root.height / 2
            color: "transparent"

            CommitGraphDock {
                anchors.fill: parent
                repositoryController: root.repositoryController
                appModel: root.appModel
                branchController: root.branchController
                commitController: root.commitController

                onCommitClicked: function(commitId) {
                    root.selectedCommit = commitId
                    console.log("Commit clicked:", commitId)
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.minimumHeight: root.height / 2
            Layout.maximumHeight: root.height / 2
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                anchors.topMargin: 32
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: root.width / 2
                    Layout.fillHeight: true
                    color: "transparent"

                    FileChangesDock {
                        anchors.fill: parent

                        repositoryController : root.repositoryController
                        commitHash : root.selectedCommit

                        onFileSelected: function(filePath){
                            root.selectedFilePath = filePath
                            let parentHash = repositoryController.getParentHash(root.selectedCommit)
                            diffView.diffData =  root.repositoryController.getCommitsDiff(parentHash, root.selectedCommit, root.selectedFilePath)
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: root.width / 2
                    Layout.fillHeight: true
                    color: "transparent"

                    DiffView {
                        id: diffView
                        anchors.fill: parent
                    }
                }
            }
        }
    }
}
