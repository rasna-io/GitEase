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

Page {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    pageId: "graph"
    title: "Graph View"
    icon: Style.icons.workflow

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
    property TagController           tagController           : null
    property ResetController         resetController         : null
    property TerminalController      terminalController      : null
    property BundleController        bundleController        : null
    property ActivityController      activityController      : null
    property var                     pluginController        : null
    property LayoutController        layoutController        : null
    property GuideController         guideController         : null
    property GitTreeController       gitTreeController       : null

    // Utility panel (moved in from the old UtilitiesPage), open by default.
    property bool                    utilityPanelOpen        : false

    property alias                   graphRef                : commitGraph

    // Remote actions (Pull / Push / Fetch) are owned by the shared RemoteOperationsSession so
    property RemoteOperationsSession remoteOperationsSession               : null
    property bool                    isFetching              : remoteOperationsSession ? remoteOperationsSession.isFetching : false
    property var                     activeFetchRemotes      : remoteOperationsSession ? remoteOperationsSession.activeFetchRemotes : []
    property var                     pendingFetchRemoteNames  : remoteOperationsSession ? remoteOperationsSession.pendingFetchRemoteNames : []
    property var                     fetchBatchResults        : remoteOperationsSession ? remoteOperationsSession.fetchBatchResults : []

    // Header exposed to MainWindow
    headerContent: Component {
        GraphViewHeader {
            id: graphViewHeader

            isGraphReady: root.graphRef !== null
            filterText: root.graphRef ? root.graphRef.filterText : (root.activePageState()?.commitGraph?.filterText || "")
            filterStartDate: root.graphRef ? root.graphRef.filterStartDate : (root.activePageState()?.commitGraph?.filterStartDate || "")
            filterEndDate: root.graphRef ? root.graphRef.filterEndDate : (root.activePageState()?.commitGraph?.filterEndDate || "")
            filterModes: root.graphRef ? root.graphRef.filterMode : (root.activePageState()?.commitGraph?.filterMode || [])
            branchNames: root.branchNames()
            branchFilter: root.graphRef ? root.graphRef.branchFilter : (root.activePageState()?.commitGraph?.branchFilter || "")
            navigationRule: root.graphRef ? root.graphRef.navigationRule : (root.activePageState()?.commitGraph?.navigationRule || navigationRules[0])
            guideController: root.guideController
            panelOpen: root.utilityPanelOpen
            remoteController: root.remoteController
            isFetching: root.isFetching

            onPanelToggleRequested: root.utilityPanelOpen = !root.utilityPanelOpen

            onPullRequested: root.pullAndUpdate()

            onPushRequested: function(force) {
                root.pushAndUpdate(force)
            }

            onFetchRequested: root.fetch()

            onFilterRequested: function(text, startDate, endDate, modes) {
                if (root.graphRef) {
                    root.graphRef.applyFilter(text, startDate, endDate, modes);
                    root.saveCommitGraphState();
                }
            }

            onBranchSelected: function(branchName) {
                if (!root.graphRef)
                    return

                if (branchName && branchName.length > 0)
                    root.graphRef.executeShowOnlyBranch(branchName)
                else
                    root.graphRef.executeShowAllBranches()

                if (branchName && branchName.length > 0)
                    root.graphRef.navigationRule = "Branch"

                root.saveCommitGraphState()
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

        root.onPageChange = function(callback) {
            root.saveCommitGraphState()
            callback(true)
        }

        Qt.callLater(root.restoreCommitGraphState)
    }

    Component.onDestruction: {
        saveCommitGraphState()
    }

    Connections {
        target: repositoryController
        function onRepositorySelected() {
            Presenter.clearSelection()
            diffView.diffData = null
        }
    }

    Connections {
        target: root.terminalController

        function onGitStateChanged() {
            utilityPanel.reload()
        }
    }

    /* Children
     * ****************************************************************************************/
    RowLayout {
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            id: mainLayout
            Layout.fillWidth: true
            Layout.fillHeight: true
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
                    resetController         : root.resetController
                    terminalController      : root.terminalController
                    guideController         : root.guideController
                    layoutController        : root.layoutController
                    pluginController        : root.pluginController
                    gitTreeController       : root.gitTreeController

                    onCommitClicked: function(commitId) { Presenter.handleCommitClicked(commitId) }
                }
            }

            DropZone {
                Layout.fillWidth: true

                FileChangesDock {
                    id: fileChangesDock

                    currentRepositoryName: root.appModel.currentRepository.name || ""

                    minimizable: true
                    icon: Style.icons.list
                    layoutController: root.layoutController
                    layoutId: "graphView.fileChangesDock"
                    SplitView.preferredWidth: lastWidth
                    SplitView.minimumWidth: 150

                    guideController: root.guideController
                    repositoryController: root.repositoryController
                    statusController: root.statusController

                    onFileSelected: function(filePath) { Presenter.handleFileSelected(filePath) }
                }

                DiffView {
                    id: diffView

                    minimizable: true
                    icon: Style.icons.file
                    layoutController: root.layoutController
                    layoutId: "graphView.diffView"
                    SplitView.fillWidth: true
                    SplitView.minimumWidth: 150

                    guideController: root.guideController
                    currentRepositoryName: root.appModel.currentRepository.name || ""
                    readOnly: true
                }
            }
        }

        // Utility panel (moved in from the old UtilitiesPage), toggled from GraphViewHeader.
        UtilityPanel {
            id: utilityPanel
            open: root.utilityPanelOpen

            branchController        : root.branchController
            remoteController        : root.remoteController
            repositoryController    : root.repositoryController
            commitController        : root.commitController
            statusController        : root.statusController
            stashController         : root.stashController
            tagController           : root.tagController
            rebaseController        : root.rebaseController
            conflictController      : root.conflictController
            bundleController        : root.bundleController
            activityController      : root.activityController
            notificationController  : root.notificationController
            guideController         : root.guideController
            userAuthenticationPopup : root.userAuthenticationPopup
            uiSessionPopups         : root.uiSessionPopups
            pluginController        : root.pluginController
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
        if (!gitTreeController)      missing.push("GitTreeController")

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

    function commitGraphState() {
        if (!root.graphRef)
            return null

        return {
            filterText      : root.graphRef.filterText || "",
            filterStartDate : root.graphRef.filterStartDate || "",
            filterEndDate   : root.graphRef.filterEndDate || "",
            filterMode      : root.graphRef.filterMode ? root.graphRef.filterMode.slice(0) : [],
            branchFilter    : root.graphRef.branchFilter || "",
            navigationRule  : root.graphRef.navigationRule || "Message"
        }
    }

    function saveCommitGraphState() {
        if (!root.graphRef)
            return

        var state = root.state || {}
        state.commitGraph = commitGraphState()
        root.state = state
    }

    function restoreCommitGraphState() {
        if (!root.graphRef || !root.state || !root.state.commitGraph)
            return

        var state = root.state.commitGraph
        root.graphRef.filterText = state.filterText || ""
        root.graphRef.filterStartDate = state.filterStartDate || ""
        root.graphRef.filterEndDate = state.filterEndDate || ""
        root.graphRef.filterMode = state.filterMode ? state.filterMode.slice(0) : []
        root.graphRef.branchFilter = state.branchFilter || ""
        root.graphRef.navigationRule = state.navigationRule || "Message"
        root.graphRef.refreshBranchFilterHeadHash()

        root.graphRef.applyFilter(
                root.graphRef.filterText,
                root.graphRef.filterStartDate,
                root.graphRef.filterEndDate,
                root.graphRef.filterMode)
    }

    function activePageState() {
        return root.state
    }

    function branchNames() {
        if (!root.branchController)
            return []

        var branches = root.branchController.getBranches()
        if (!branches)
            return []

        var names = []
        for (var i = 0; i < branches.length; i++) {
            var branch = branches[i]
            if (branch && branch.name)
                names.push(branch.name)
        }

        return names
    }

    function fetch() {
        root.remoteOperationsSession?.fetch()
    }

    function push(force) {
        root.remoteOperationsSession?.push(force)
    }

    function pushAndUpdate(force) {
        root.remoteOperationsSession?.pushAndUpdate(force)
    }

    function pull(secret) {
        root.remoteOperationsSession?.pull(secret)
    }

    function pullAndUpdate(secret) {
        root.remoteOperationsSession?.pullAndUpdate(secret)
    }
}
