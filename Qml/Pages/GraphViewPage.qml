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

    /* Property Declarations
     * ****************************************************************************************/
    property var                     page                    : null
    property AppModel                appModel                : null

    property BranchController        branchController        : null
    property RemoteController        remoteController        : null
    property UserAuthenticationPopup userAuthenticationPopup : null
    property CommitController        commitController        : null
    property StatusController        statusController        : null
    property RepositoryController    repositoryController    : null
    property NotificationController  notificationController  : null
    property UiSessionPopups         uiSessionPopups         : null
    property StashController         stashController         : null
    property ConflictController      conflictController      : null
    property MergeController         mergeController         : null
    property RebaseController        rebaseController        : null
    property CherryPickController    cherryPickController    : null
    property TagController          tagController           : null


    property alias                   graphRef                : commitGraph

    // Header exposed to MainWindow
    property Component headerContent: Component {
        GraphViewHeader {
            id: graphViewHeader

            isGraphReady: root.graphRef !== null

            onFilterRequested: function(text, startDate, endDate, modes) {
                if (root.graphRef) {
                    root.graphRef.applyFilter(text, startDate, endDate, modes);
                }
            }

            onNextRequested: function(rule) {
                root.graphRef.selectNext(rule);
            }

            onPreviousRequested: function(rule) {
                root.graphRef.selectPrevious(rule);
            }

            onReloadRequested: function() {
                root.graphRef.reloadAll();
            }
        }
    }

    /* Signals and Connections
     * ****************************************************************************************/
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

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/
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
                remoteController        : root.remoteController
                userAuthenticationPopup : root.userAuthenticationPopup
                tagController            : root.tagController
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

                currentRepositoryName: root.appModel.currentRepository.name || ""

                repositoryController: root.repositoryController
                statusController: root.statusController

                onFileSelected: function(filePath) { Presenter.handleFileSelected(filePath) }
            }

            DiffView {
                id: diffView

                currentRepositoryName: root.appModel.currentRepository.name || ""
                readOnly: true
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function initPresenter() {
        if (!notificationController) {
            console.error("GraphViewPage: missing Notification Controller")
            return
        }

        var missing = []

        if (!appModel)               missing.push("AppModel")
        if (!branchController)       missing.push("BranchController")
        if (!remoteController)       missing.push("RemoteController")
        if (!commitController)       missing.push("CommitController")
        if (!statusController)       missing.push("StatusController")
        if (!repositoryController)   missing.push("RepositoryController")
        if (!stashController)        missing.push("StashController")
        if (!mergeController)        missing.push("MergeController")
        if (!rebaseController)       missing.push("RebaseController")
        if (!cherryPickController)   missing.push("CherryPickController")
        if (!conflictController)     missing.push("ConflictController")

        if (missing.length > 0) {
            notificationController.error(
                    "Commit Graph cannot work correctly – missing: " + missing.join(", "),
                    "Initialization Error", 5000
            )
            return
        }

        Presenter.init({
            commitGraph     : commitGraph,
            fileChangesDock : fileChangesDock,
            diffView        : diffView,
            statusController: statusController,
            commitController: commitController
        })
    }
}
