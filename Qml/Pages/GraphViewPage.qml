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

    // Remote actions state (Pull / Push / Fetch, moved in from CommittingPageHeader)
    property bool                    isFetching              : false
    property var                     activeFetchRemotes      : []
    property string                  authPurpose             : "push"  // "push" | "pushForce" | "fetch" | "pull"
    property var                     pendingFetchRemoteNames  : []
    property var                     fetchBatchResults        : []

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
            root.reloadUtilityPanel()
        }
    }

    // Guarded: only reacts when this page itself opened the shared auth popup,
    // so it doesn't misfire on a push/pull/fetch started elsewhere (e.g. CommittingPage, RemoteView).
    Connections {
        id: remoteAuthConnection
        target: root.userAuthenticationPopup
        enabled: false

        function onPasswordConfirm(password) {
            if (root.authPurpose === "fetch") {
                let failed = []
                for (let i = 0; i < root.pendingFetchRemoteNames.length; i++) {
                    let name = root.pendingFetchRemoteNames[i]
                    let res = root.remoteController.fetchWithToken(name, password)
                    if (res.success) {
                        if (root.activeFetchRemotes.indexOf(name) === -1)
                            root.activeFetchRemotes.push(name)
                    } else {
                        failed.push({ name: name, message: res.errorMessage || "Unknown error" })
                        root.fetchBatchResults.push({
                                                        remote: name,
                                                        success: false,
                                                        errorMessage: res.errorMessage || "Unknown error",
                                                        data: { timestamp: Qt.formatDateTime(new Date(), Qt.ISODate), status: "Fetch did not start" }
                                                    })
                    }
                }
                if (failed.length > 0 && root.notificationController) {
                    root.notificationController.error("Fetch failed for: " + failed.map(function(f){ return f.name + " (" + f.message + ")" }).join("; "), "Fetch Error", 7000)
                }
                root.isFetching = root.activeFetchRemotes.length > 0
                root.pendingFetchRemoteNames = []
                remoteAuthConnection.enabled = false
                return
            }

            if (root.authPurpose === "pull") {
                root.pull(password)
                remoteAuthConnection.enabled = false
                return
            }

            let branchName = root.branchController.getCurrentBranchName()
            if (branchName.length === 0) {
                root.notificationController.error("Current branch name is invalid", "Branch Error", 5000)
            } else {
                let isForce = root.authPurpose === "pushForce"
                root.remoteController.push("origin", branchName, password, isForce)
                root.notificationController.info("Push operation started", "Push", 3000)
            }
            remoteAuthConnection.enabled = false
        }

        function onRejected() {
            if (root.authPurpose === "fetch") {
                root.isFetching = root.activeFetchRemotes.length > 0
                root.pendingFetchRemoteNames = []
            }
            remoteAuthConnection.enabled = false
        }
    }

    Connections {
        target: root.remoteController

        function onFetchFinished(result) {
            if (!result || !result.remote)
                return

            const remoteName = result.remote
            root.activeFetchRemotes = root.activeFetchRemotes.filter(function(name) { return name !== remoteName })
            root.fetchBatchResults.push(result)

            if (root.notificationController) {
                if (result.success)
                    root.notificationController.success("Fetched from " + remoteName, "Fetch", 5000)
                else
                    root.notificationController.error("Fetch failed for " + remoteName + ": " + (result.errorMessage || "Unknown error"), "Fetch Error", 7000)
            }

            root.isFetching = root.activeFetchRemotes.length > 0 || root.pendingFetchRemoteNames.length > 0
            if (root.activeFetchRemotes.length === 0 && root.pendingFetchRemoteNames.length === 0 && root.fetchBatchResults.length > 0) {
                let popup = root.uiSessionPopups?.fetchSummaryPopup
                if (popup) {
                    popup.results = []
                    popup.results = root.fetchBatchResults
                    popup.open()
                }
            }
        }

        function onPushFinished(result) {
            if (!result || result.remote !== "origin")
                return

            root.isFetching = false

            if (result.success) {
                let isForce = result.data.force === true
                if (root.notificationController)
                    root.notificationController.success(isForce ? "Changes force pushed successfully" : "Changes pushed successfully", isForce ? "Push Force" : "Push", 3000)
            } else {
                if (root.notificationController)
                    root.notificationController.error(result.errorMessage || "Push error", "Push Error", 5000)
            }
        }
    }

    Connections {
        target: root.uiSessionPopups ? root.uiSessionPopups.fetchSummaryPopup : null

        function onClosed() {
            root.fetchBatchResults = []
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

            ColumnLayout {
                anchors.fill: parent
                spacing: 0

                TextField {
                    id: utilityPanelFilterField
                    Layout.fillWidth: true
                    Layout.margins: Style.dp(8)
                    minHeight: 23
                    placeholderText: qsTr("Filter...")
                    backgroundColor: Style.colors.secondaryBackground
                    borderWidth: 1
                    borderColor: Style.colors.secondaryBorder
                    focusBorderWidth: 1
                    font.family: Style.fontTypes.roboto
                    font.weight: 400
                    font.pixelSize: Style.appFont.captionPt

                    onTextChanged: utilityPanelFlow.filterText = text
                }

                Flickable {
                    id: utilityPanelFlick
                    Layout.fillWidth: true
                    Layout.fillHeight: true
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
                        property string filterText: ""

                        function matchesFilter(sectionTitle) {
                            var needle = utilityPanelFlow.filterText.trim().toLowerCase()
                            if (needle.length === 0)
                                return true
                            return sectionTitle.toLowerCase().indexOf(needle) !== -1
                        }

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
                            visible: utilityPanelFlow.matchesFilter("Export / Import Project")
                            branchController: root.branchController
                            bundleController: root.bundleController
                            notificationController: root.notificationController
                            guideController: root.guideController
                        }

                        RemoteView {
                            visible: utilityPanelFlow.matchesFilter("Remotes")
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
                            visible: utilityPanelFlow.matchesFilter("Branch Management")
                            branchController: root.branchController
                            addBranchPopup: uiSessionPopups.addBranchPopup
                            notificationController: root.notificationController
                            guideController: root.guideController

                            onHoveredChanged: utilityPanelFlow.updateDockHovered()
                        }


                        StashManagerDock {
                            id: stashManagerDock
                            visible: utilityPanelFlow.matchesFilter("Stash Manager")
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
                            visible: utilityPanelFlow.matchesFilter("Tag Management")
                            tagController: root.tagController
                            addTagPopup: uiSessionPopups.addTagPopup
                            guideController: root.guideController
                            notificationController: root.notificationController

                            onHoveredChanged: utilityPanelFlow.updateDockHovered()
                        }

                        RecentActivityDock {
                            visible: utilityPanelFlow.matchesFilter("Recent Activity")
                            activityController: root.activityController
                            guideController: root.guideController

                            onHoveredChanged: utilityPanelFlow.updateDockHovered()
                        }

                        RepositoriesHistoryDock {
                            visible: utilityPanelFlow.matchesFilter("Repositories History")
                            repositoryController: root.repositoryController
                            guideController: root.guideController

                            onHoveredChanged: utilityPanelFlow.updateDockHovered()
                        }

                        RebaseDock {
                            id: rebaseDock
                            visible: utilityPanelFlow.matchesFilter("Rebase")
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
                                visible: utilityPanelFlow.matchesFilter(modelData.title ?? "")

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

    function fetch() {
        let remotesRes = remoteController.getRemotes()
        if (!remotesRes.success || !remotesRes.data || remotesRes.data.length === 0) {
            if (notificationController)
                notificationController.error("No remotes configured", "Fetch", 5000)
            return
        }
        root.fetchBatchResults = []
        let httpsRemotes = []
        let sshFailed = []
        root.activeFetchRemotes = []
        root.isFetching = true
        for (let i = 0; i < remotesRes.data.length; i++) {
            let remote = remotesRes.data[i]
            let urlRes = remoteController.getRemoteUrl(remote.name)
            if (!urlRes.success) {
                sshFailed.push({ name: remote.name, message: urlRes.errorMessage || "No URL" })
                continue
            }
            let url = urlRes.data.url
            let protocol = repositoryController.detectGitProtocol(url)
            switch (protocol) {
            case RepositoryController.GitProtocol.SSH: {
                let res = remoteController.fetch(remote.name)
                if (res.success) {
                    if (root.activeFetchRemotes.indexOf(remote.name) === -1)
                        root.activeFetchRemotes.push(remote.name)
                } else {
                    let msg = res.errorMessage || "Fetch failed"
                    sshFailed.push({ name: remote.name, message: msg })
                    root.fetchBatchResults.push({
                                                    remote: remote.name,
                                                    success: false,
                                                    errorMessage: msg,
                                                    data: { timestamp: Qt.formatDateTime(new Date(), Qt.ISODate), status: "Fetch did not start" }
                                                })
                }
                break
            }
            case RepositoryController.GitProtocol.HTTPS:
            case RepositoryController.GitProtocol.HTTP:
                httpsRemotes.push(remote.name)
                break
            default:
                sshFailed.push({ name: remote.name, message: "Unsupported protocol" })
            }
        }
        if (sshFailed.length > 0 && notificationController) {
            let msg = sshFailed.map(f => f.name + ": " + f.message).join("; ")
            notificationController.error(msg, "Fetch Error", 7000)
        }
        if (httpsRemotes.length > 0) {
            root.pendingFetchRemoteNames = httpsRemotes
            root.authPurpose = "fetch"
            remoteAuthConnection.enabled = true
            userAuthenticationPopup.open()
        }
        if (httpsRemotes.length === 0 && root.activeFetchRemotes.length === 0)
            root.isFetching = false
    }

    function push(force) {
        force = force || false

        let urlRes = remoteController.getRemoteUrl("origin")
        if (!urlRes.success) {
            root.notificationController.error(urlRes.errorMessage || "Failed to get remote URL", `${force ? "Force" : ""} Push Error`, 5000)
            return
        }
        let protocol = repositoryController.detectGitProtocol(urlRes.data.url)
        switch (protocol) {
        case RepositoryController.GitProtocol.SSH: {
            let branchName = branchController.getCurrentBranchName()
            remoteController.push("origin", branchName, force)
            root.notificationController.info("Push operation started", "Push", 3000)

            break
        }

        // Fall-through: both HTTP/HTTPS require auth popup
        case RepositoryController.GitProtocol.HTTPS:
        case RepositoryController.GitProtocol.HTTP:
            root.authPurpose = force ? "pushForce" : "push"
            remoteAuthConnection.enabled = true
            userAuthenticationPopup.open()
            break
        default:
            root.notificationController.error("Unsupported protocol", `${force ? "Force" : ""} Push Error`, 5000)
        }
    }

    function pushAndUpdate(force) {
        root.push(force)
    }

    function pull(secret: string) {
        let res = remoteController.getRemoteUrl("origin")
        if (!res.success) {
            if (notificationController)
                notificationController.error(res.errorMessage || "Failed to get remote URL", "Pull Error", 5000)
            return
        }
        let url = res.data.url
        let protocol = repositoryController.detectGitProtocol(url)
        switch (protocol) {
        case RepositoryController.GitProtocol.SSH: {
            let pullRes = remoteController.pull("origin", root.branchController.getCurrentBranchName())
            if (!pullRes.success) {
                if (notificationController)
                    notificationController.error(pullRes.errorMessage || "Pull failed", "Pull Error", 5000)
            } else {
                if (notificationController)
                    notificationController.success("Pulled successfully", "Pull", 3000)
            }
            break
        }
        case RepositoryController.GitProtocol.HTTPS:
        case RepositoryController.GitProtocol.HTTP:
            if(secret.length > 0 && secret !== "undefined" && secret) {
                let res = root.remoteController.pull("origin", root.branchController.getCurrentBranchName(), secret)
                if (!res.success) {
                    if (notificationController)
                        notificationController.error(res.errorMessage || "Pull failed", "Pull Error", 5000)
                } else {
                    if (notificationController)
                        notificationController.success("Pulled successfully", "Pull", 3000)
                }
            }else {
                root.authPurpose = "pull"
                remoteAuthConnection.enabled = true
                userAuthenticationPopup.open()
            }
            break
        default:
            if (notificationController)
                notificationController.error("Unsupported protocol", "Pull Error", 5000)
        }
    }

    function pullAndUpdate(secret: string) {
        root.pull(secret)
    }
}
