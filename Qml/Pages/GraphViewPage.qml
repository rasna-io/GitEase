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

DockAblePage {
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

    readonly property var currentRepo: appModel?.currentRepository ?? null

    property string selectedCommit: ""
    property string selectedFilePath: ""

    CommitGraphDock {
        id: commitGraphDock

        height: root.height / 2
        width: root.width

        repositoryController: root.repositoryController
        appModel: root.appModel
        branchController: root.branchController
        commitController: root.commitController

        onCommitClicked: function(commitId) {
            root.selectedCommit = commitId
            console.log("Commit clicked:", commitId)
        }

        onIsDraggingChanged: {
            root.showDropZone = commitGraphDock.isDragging
            commitGraphDock.parent = root
        }

        onDockPositionChanged: {
            root.moveDock(commitGraphDock.dockId)
        }

        Component.onCompleted: {
            root.docks.push(commitGraphDock)
            root.docks = root.docks.slice(0)
        }
    }

    FileChangesDock {
        id: fileChangesDock
        height: root.height / 2
        width: root.width / 2

        repositoryController : root.repositoryController
        statusController: root.statusController
        commitHash : root.selectedCommit

        onFileSelected: function(filePath){
            root.selectedFilePath = filePath
            let parentHash = root.commitController.getParentHash(root.selectedCommit)
            let res = root.statusController.getDiff(parentHash, root.selectedCommit, root.selectedFilePath)

            if (res.success) {
                diffView.diffData = res.data
            }
        }

        onIsDraggingChanged: {
            root.showDropZone = isDragging
            fileChangesDock.parent = root
        }

        onDockPositionChanged: {
            root.moveDock(fileChangesDock.dockId)
        }

        Component.onCompleted: {
            root.docks.push(fileChangesDock)
            root.docks = root.docks.slice(0)
        }
    }

    DiffView {
        id: diffView

        height: root.height / 2
        width: root.width / 2

        onIsDraggingChanged: {
            root.showDropZone = isDragging
            diffView.parent = root
        }

        onDockPositionChanged: {
            root.moveDock(diffView.dockId)
        }

        Component.onCompleted: {
            root.docks.push(diffView)
            root.docks = root.docks.slice(0)
        }
    }
}
