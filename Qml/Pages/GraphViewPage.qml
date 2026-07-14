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

    // Utility panel (moved in from the old UtilitiesPage), open by default.
    property bool                    utilityPanelOpen        : true

    property alias                   graphRef                : commitGraph

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

            onPanelToggleRequested: root.utilityPanelOpen = !root.utilityPanelOpen

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
            root.reloadUtilityPanel()
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
        Rectangle {
            id: utilityPanel
            visible: root.utilityPanelOpen
            Layout.fillHeight: true
            Layout.preferredWidth: Style.dp(279)

            color: Style.colors.primaryBackground
            border.width: 1
            border.color: Style.colors.primaryBorder

            Flickable {
                id: utilityPanelFlick
                anchors.fill: parent
                clip: true

                interactive: !utilityPanelFlow.dockHovered
                flickableDirection: Flickable.VerticalFlick
                boundsBehavior: Flickable.StopAtBounds

                contentWidth: utilityPanelFlow.width
                contentHeight: utilityPanelFlow.implicitHeight

                ScrollBar.vertical: ScrollBar {
                    policy: ScrollBar.AsNeeded
                }

                Flow {
                    id: utilityPanelFlow
                    width: utilityPanelFlick.width

                    property bool dockHovered: false

                    function scrollBlockingHovered(item) {
                        return item
                            && item.visible !== false
                            && item.hasOwnProperty("pageScrollBlocking")
                            && item.pageScrollBlocking === true
                            && item.hasOwnProperty("hovered")
                            && item.hovered === true
                    }

                    function updateDockHovered() {
                        for (let i = 0; i < children.length; ++i) {
                            const child = children[i]
                            if (scrollBlockingHovered(child) || scrollBlockingHovered(child.item)) {
                                utilityPanelFlow.dockHovered = true
                                return
                            }
                        }

                        utilityPanelFlow.dockHovered = false
                    }

                    function setupPluginDock(item) {
                        if (!item)
                            return

                        if (item.hasOwnProperty("pageScrollBlocking")
                                && item.pageScrollBlocking === true
                                && item.hoveredChanged)
                            {
                            item.hoveredChanged.connect(utilityPanelFlow.updateDockHovered)
                        }

                        updateDockHovered()
                    }

                    ImportExportBundleDock {
                        branchController: root.branchController
                        bundleController: root.bundleController
                        notificationController: root.notificationController
                        guideController: root.guideController
                    }

                    RemoteView {
                        remoteController: root.remoteController
                        repositoryController: root.repositoryController
                        userAuthenticationPopup: root.userAuthenticationPopup
                        uiSessionPopups: root.uiSessionPopups
                        addEditRemotePopup: uiSessionPopups.addEditRemotePopup
                        notificationController: root.notificationController
                        guideController: root.guideController

                        onHoveredChanged: utilityPanelFlow.updateDockHovered()
                    }


                    BranchManagementView {
                        id: branchManagementView
                        branchController: root.branchController
                        addBranchPopup: uiSessionPopups.addBranchPopup
                        notificationController: root.notificationController
                        guideController: root.guideController

                        onHoveredChanged: utilityPanelFlow.updateDockHovered()
                    }


                    StashManagerDock {
                        id: stashManagerDock
                        stashController: root.stashController
                        commitController: root.commitController
                        statusController: root.statusController
                        addStashPopup: uiSessionPopups.addStashPopup
                        manageStashPopup: uiSessionPopups.manageStashPopup
                        guideController: root.guideController

                        notificationController: root.notificationController

                        onHoveredChanged: utilityPanelFlow.updateDockHovered()
                    }

                    TagManagementView {
                        id: tagManagementView
                        tagController: root.tagController
                        addTagPopup: uiSessionPopups.addTagPopup
                        guideController: root.guideController
                        notificationController: root.notificationController

                        onHoveredChanged: utilityPanelFlow.updateDockHovered()
                    }

                    RecentActivityDock {
                        activityController: root.activityController
                        guideController: root.guideController

                        onHoveredChanged: utilityPanelFlow.updateDockHovered()
                    }

                    RepositoriesHistoryDock {
                        repositoryController: root.repositoryController
                        guideController: root.guideController

                        onHoveredChanged: utilityPanelFlow.updateDockHovered()
                    }

                    RebaseDock {
                        id: rebaseDock
                        branchController        : root.branchController
                        rebaseController        : root.rebaseController
                        commitController        : root.commitController
                        statusController        : root.statusController
                        notificationController  : root.notificationController
                        conflictController      : root.conflictController
                        guideController         : root.guideController
                    }

                    // ── Plugin docks ─────────────────────────────────────────────────
                    Repeater {
                        model: root.pluginController?.pluginManager?.registeredDocks ?? []

                        delegate: Loader {
                            width:  Style.dp(279)
                            height: 390

                            source: modelData.url

                            onLoaded: {
                                if (!item) return
                                if (item.hasOwnProperty("pluginManager"))
                                    item.pluginManager = Qt.binding(function() { return root.pluginController?.pluginManager })
                                if (item.hasOwnProperty("pluginId"))
                                    item.pluginId = modelData.id
                                utilityPanelFlow.setupPluginDock(item)
                                if (item.hasOwnProperty("repositoryController"))
                                    item.repositoryController = Qt.binding(function() { return root.repositoryController })
                                if (item.hasOwnProperty("branchController"))
                                    item.branchController = Qt.binding(function() { return root.branchController })
                                if (item.hasOwnProperty("remoteController"))
                                    item.remoteController = Qt.binding(function() { return root.remoteController })
                                if (item.hasOwnProperty("userAuthenticationPopup"))
                                    item.userAuthenticationPopup = Qt.binding(function() { return root.userAuthenticationPopup })
                                if (item.hasOwnProperty("uiSessionPopups"))
                                    item.uiSessionPopups = Qt.binding(function() { return root.uiSessionPopups })
                                if (item.hasOwnProperty("notificationController"))
                                    item.notificationController = Qt.binding(function() { return root.notificationController })
                                if (item.hasOwnProperty("guideController"))
                                    item.guideController = Qt.binding(function() { return root.guideController })       
                                if (item.hasOwnProperty("commitController"))
                                    item.commitController = Qt.binding(function() { return root.commitController })
                                if (item.hasOwnProperty("statusController"))
                                    item.statusController = Qt.binding(function() { return root.statusController })
                                if (item.hasOwnProperty("stashController"))
                                    item.stashController = Qt.binding(function() { return root.stashController })
                                if (item.hasOwnProperty("tagController"))
                                    item.tagController = Qt.binding(function() { return root.tagController })
                                if (item.hasOwnProperty("eventBus"))
                                    item.eventBus = Qt.binding(function() { return root.pluginController?.pluginManager })
                            }

                            onStatusChanged: {
                                if (status === Loader.Error)
                                    console.error("[GraphViewPage] Failed to load plugin dock:", source)
                            }
                        }
                    }
                }
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

    function reloadUtilityPanel() {
        branchManagementView.update()
        stashManagerDock.updateStashes()
        tagManagementView.update()
        rebaseDock.refreshBranches()
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
}
