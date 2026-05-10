import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

import "qrc:/GitEase/Qml/Core/Scripts/GraphViewPresenter.js" as Presenter

/*! ***********************************************************************************************
 * GraphViewPage
 * Graph View Page shown Commit Graph Dock, File Changes and Diff View
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations */
    property var                    page                    : null
    property AppModel               appModel                : null

    property BranchController       branchController        : null
    property CommitController       commitController        : null
    property StatusController       statusController        : null
    property RepositoryController   repositoryController    : null
    property NotificationController notificationController  : null
    property UiSessionPopups        uiSessionPopups         : null
    property StashController        stashController         : null
    property ConflictController     conflictController      : null
    property MergeController        mergeController         : null
    property RebaseController       rebaseController        : null
    property CherryPickController   cherryPickController    : null

    property alias graphRef: commitGraph

    anchors.fill: parent

    // Header exposed to MainWindow
    property Component headerContent: Component {
        GraphViewHeader {
            id: graphViewHeader
            commitGraph: root.graphRef
        }
    }

    Component.onCompleted: {
        Qt.callLater(initPresenter)
    }

    Connections {
        target: repositoryController
        function onRepositorySelected() {
            Presenter.clearSelection()
            diffView.diffData = null
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        DropZone {
            id: commitGraphDock
            Layout.fillWidth: true

            CommitGraphDock {
                id: commitGraph

                repositoryController    : root.repositoryController
                appModel                : root.appModel
                branchController        : root.branchController
                mergeController         : root.mergeController
                rebaseController        : root.rebaseController
                cherryPickController    : root.cherryPickController
                addBranchPopup          : uiSessionPopups.addBranchPopup
                addTagPopup             : uiSessionPopups.addTagPopup
                commitController        : root.commitController
                statusController        : root.statusController
                notificationController  : root.notificationController
                stashController         : root.stashController
                conflictController      : root.conflictController

                onCommitClicked: function(commitId) { Presenter.handleCommitClicked(commitId) }
            }
        }

        DropZone {
            Layout.fillWidth: true

            FileChangesDock {
                id: fileChangesDock

                repositoryController: root.repositoryController
                statusController: root.statusController

                onFileSelected: function(filePath) { Presenter.handleFileSelected(filePath) }
            }

            DiffView {
                id: diffView
                readOnly: true
            }
        }
    }

    function initPresenter() {
        Presenter.init({
            commitGraph     : commitGraph,
            fileChangesDock : fileChangesDock,
            diffView        : diffView,
            statusController: statusController,
            commitController: commitController
        })
    }
}
