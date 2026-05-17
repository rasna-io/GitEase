import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

import "qrc:/GitEase/Qml/Core/Scripts/GraphLayout.js"            as GraphLayout
import "qrc:/GitEase/Qml/Core/Scripts/GraphUtils.js"             as GraphUtils
import "qrc:/GitEase/Qml/Core/Scripts/CommitGraphDataLoader.js"  as DataLoader
import "qrc:/GitEase/Qml/Core/Scripts/CommitGraphFilter.js"      as Filter
import "qrc:/GitEase/Qml/Core/Scripts/CommitGraphNavigation.js"  as Navigation
import "qrc:/GitEase/Qml/Core/Scripts/CommitGraphMenuBuilder.js" as MenuBuilder

/*! ***********************************************************************************************
 * CommitGraphDock
 * ************************************************************************************************/

DetachablePanel {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel               appModel                : null

    property BranchController       branchController        : null
    property MergeController        mergeController         : null
    property RebaseController       rebaseController        : null
    property CherryPickController   cherryPickController    : null
    property ConflictController     conflictController      : null
    property TagController          tagController           : null
    property StatusController       statusController        : null
    property CommitController       commitController        : null
    property RepositoryController   repositoryController    : null
    property NotificationController notificationController  : null
    property StashController        stashController         : null

    property AddBranchPopup         addBranchPopup          : null
    property AddTagPopup            addTagPopup             : null


    property var    allCommits      : []
    property var    commits         : []
    property var    allCommitsHash  : ({})
    property string headHash        : ""

    property var selectedCommitHashes   : []
    property var selectedCommit         : null
    property int lastSelectedIndex      : -1

    property string navigationRule  : "Message"
    property string filterText      : ""
    property string filterStartDate : ""
    property string filterEndDate   : ""
    property var    filterMode      : []

    property int    pageSize        : 200
    property int    commitsOffset   : 0
    property bool   isLoadingMore   : false
    property bool   hasMoreCommits  : true

    property var commitPositions    : ({})
    property int commitItemHeight   : 24
    property int commitItemSpacing  : 4
    property int columnSpacing      : 30

    property int commitsColGraphWidth       : parent.width * 0.08
    property int commitsColBranchTagWidth   : parent.width * 0.17
    property int commitsColMessageWidth     : parent.width * 0.6
    property int commitsColAuthorWidth      : parent.width * 0.08
    property int commitsColDateWidth        : parent.width * 0.17

    readonly property int minColGraphWidth      : 60
    readonly property int minColBranchTagWidth  : 80
    readonly property int minColMessageWidth    : 100
    readonly property int minColAuthorWidth     : 60
    readonly property int minColDateWidth       : 80

    readonly property bool hasAnyFilter         : Filter.hasAnyFilter(root.filterText, root.filterStartDate, root.filterEndDate)

    /* Signals
     * ****************************************************************************************/
    signal commitClicked(string commitId)

    /* Object Properties
     * ****************************************************************************************/
    title: qsTr("Commit Graph")

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.fill: parent
        color: Style.colors.primaryBackground

        EmptyStateView {
            title: "no commit to show"
            details: root.emptyStateDetailsText()
            visible: !root.commits || root.commits.length === 0
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: (commits && commits.length > 0) ? 30 : 0
                visible: commits && commits.length > 0
                color: Style.colors.primaryBackground

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    ResizableColumnHeader {
                        Layout.preferredWidth: root.commitsColGraphWidth
                        label: "Graph"
                        onResized: function(delta) {
                            var newWidth = Math.max(root.minColGraphWidth, root.commitsColGraphWidth + delta)
                            var actualDelta = newWidth - root.commitsColGraphWidth
                            var nextWidth = root.commitsColBranchTagWidth - actualDelta
                            if (nextWidth < root.minColBranchTagWidth) {
                                nextWidth = root.minColBranchTagWidth
                                newWidth = root.commitsColGraphWidth + (root.commitsColBranchTagWidth - root.minColBranchTagWidth)
                            }
                            root.commitsColGraphWidth = newWidth
                            root.commitsColBranchTagWidth = nextWidth
                        }
                    }

                    ResizableColumnHeader {
                        Layout.preferredWidth: root.commitsColBranchTagWidth
                        label: "Branch/Tag"
                        onResized: function(delta) {
                            var newWidth = Math.max(root.minColBranchTagWidth, root.commitsColBranchTagWidth + delta)
                            var actualDelta = newWidth - root.commitsColBranchTagWidth
                            var nextWidth = root.commitsColMessageWidth - actualDelta
                            if (nextWidth < root.minColMessageWidth) {
                                nextWidth = root.minColMessageWidth
                                newWidth = root.commitsColBranchTagWidth + (root.commitsColMessageWidth - root.minColMessageWidth)
                            }
                            root.commitsColBranchTagWidth = newWidth
                            root.commitsColMessageWidth = nextWidth
                        }
                    }

                    ResizableColumnHeader {
                        Layout.preferredWidth: root.commitsColMessageWidth
                        label: "Message"
                        onResized: function(delta) {
                            var newWidth = Math.max(root.minColMessageWidth, root.commitsColMessageWidth + delta)
                            var actualDelta = newWidth - root.commitsColMessageWidth
                            var nextWidth = root.commitsColAuthorWidth - actualDelta
                            if (nextWidth < root.minColAuthorWidth) {
                                nextWidth = root.minColAuthorWidth
                                newWidth = root.commitsColMessageWidth + (root.commitsColAuthorWidth - root.minColAuthorWidth)
                            }
                            root.commitsColMessageWidth = newWidth
                            root.commitsColAuthorWidth = nextWidth
                        }
                    }

                    ResizableColumnHeader {
                        Layout.preferredWidth: root.commitsColAuthorWidth
                        label: "Author"
                        onResized: function(delta) {
                            var newWidth = Math.max(root.minColAuthorWidth, root.commitsColAuthorWidth + delta)
                            var actualDelta = newWidth - root.commitsColAuthorWidth
                            var nextWidth = root.commitsColDateWidth - actualDelta
                            if (nextWidth < root.minColDateWidth) {
                                nextWidth = root.minColDateWidth
                                newWidth = root.commitsColAuthorWidth + (root.commitsColDateWidth - root.minColDateWidth)
                            }
                            root.commitsColAuthorWidth = newWidth
                            root.commitsColDateWidth = nextWidth
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.commitsColDateWidth
                        Layout.fillHeight: true
                        color: Style.colors.primaryBackground
                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Date"
                            color: Style.colors.foreground
                            font.pixelSize: 11
                            font.bold: true
                        }
                    }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                Flickable {
                    id: graphFlickable
                    Layout.preferredWidth: root.commitsColGraphWidth + root.commitsColBranchTagWidth
                    Layout.fillHeight: true
                    contentWidth: children[0].width
                    contentHeight: children[0].height
                    clip: true
                    interactive: false
                    contentY: commitsListView.contentY
                    flickableDirection: Flickable.VerticalFlick

                    MouseArea {
                        anchors.fill: parent
                        onWheel: function(wheel) {
                            var newY = commitsListView.contentY - wheel.angleDelta.y
                            var maxY = Math.max(0, commitsListView.contentHeight - commitsListView.height)
                            commitsListView.contentY = Math.max(0, Math.min(newY, maxY))
                        }
                    }

                    CommitGraphCanvas {
                        id: graphCanvas
                        width: root.commitsColGraphWidth + root.commitsColBranchTagWidth
                        height: Math.max(commitsListView.contentHeight, graphFlickable.height)
                        commits: root.commits
                        commitPositions: root.commitPositions
                        columnSpacing: root.columnSpacing
                        commitItemHeight: root.commitItemHeight
                        commitItemSpacing: root.commitItemSpacing
                        selectedHashes: root.selectedCommitHashes
                        headHash: root.headHash
                        showAvatar: root.appModel?.appSettings?.generalSettings?.showAvatar ?? true
                        graphColumnWidth: root.commitsColGraphWidth
                        branchTagColumnWidth: root.commitsColBranchTagWidth
                        allCommitsHash: root.allCommitsHash
                        onInfiniteScroll: root.loadMoreCommits()
                    }
                }

                ListView {
                    id: commitsListView

                    Layout.fillWidth    : true
                    Layout.fillHeight   : true
                    Layout.minimumWidth : 100

                    model   : root.commits
                    clip    : true

                    delegate: CommitListDelegate {
                        height: root.commitItemHeight + root.commitItemSpacing * 2

                        messageWidth: root.commitsColMessageWidth
                        authorWidth : root.commitsColAuthorWidth
                        dateWidth   : root.commitsColDateWidth

                        indicatorColor: {
                            if (modelData && modelData.isUncommitted)
                                return "#888888"

                            if (!modelData || !modelData.colorKey)
                                return GraphUtils.getCategoryColor("default")

                            return GraphUtils.getCategoryColor(modelData.colorKey)
                        }

                        isSelected  : root.isCommitSelected(modelData.hash)
                        isHead      : modelData ? modelData.hash === root.headHash  : false
                        isStash     : modelData ? modelData.isStash === true        : false
                        parentRoot  : root

                        onItemClicked: function(button, modifiers, idx, mouseX, mouseY) {
                            root.handleItemClick(modelData, button, modifiers, idx, mouseX, mouseY)
                        }

                        onItemDoubleClicked: function(button, modifiers, idx) {
                            root.handleItemDoubleClick(modelData, button, modifiers, idx)
                        }
                    }
                }
            }
        }
    }

    ContextMenu {
        id: contextMenu
        width: 250
    }

    Connections {
        target: Style
        function onCurrentThemeChanged() {
            graphCanvas.requestPaint()
        }
    }

    Connections {
        target: root.repositoryController
        function onRepositorySelected() {
            root.reloadAll()
        }
    }

    Connections {
        target: root.addBranchPopup

        function onBranchCreatedSuccessfully() {
            root.selectedCommit         = null
            root.selectedCommitHashes   = []
            root.lastSelectedIndex      = -1
            root.reloadAll()
        }
    }

    Connections {
        target: root.addTagPopup
        function onTagCreatedSuccessfully() {
            root.selectedCommit = null
            root.reloadAll()
        }
    }

    Connections {
        target: root.appModel?.appSettings?.generalSettings ?? null
        function onShowAvatarChanged() {
            graphCanvas.requestPaint()
        }

        function onShowStashNodesChanged() {
            root.refreshStashNodes()
        }
    }

    Connections {
        target: root
        function onGraphColumnWidthChanged() {
            graphCanvas.requestPaint()
        }

        function onBranchTagColumnWidthChanged() {
            graphCanvas.requestPaint()
        }
    }

    onRepositoryControllerChanged: root.reloadAll()

    onStashControllerChanged: {
        if (root.allCommits.length)
            root.refreshStashNodes()
    }

    onAllCommitsChanged: {
        root.allCommitsHash = {}
        for (var i = 0; i < root.allCommits.length; i++) {
            var c = root.allCommits[i]
            if (c && c.hash) root.allCommitsHash[c.hash] = c.hash
        }
    }

    ConflictPopup {
        id: mergeConflictPopup
        currentOperation: ConflictPopup.OperationType.Merge
        mergeController: root.mergeController
        conflictController: root.conflictController
        notificationController: root.notificationController
        statusController: root.statusController
    }

    MergeMethodPopup { id: mergeMethodPopup }

    ConflictPopup {
        id: rebaseConflictPopup
        currentOperation: ConflictPopup.OperationType.Rebase
        rebaseController: root.rebaseController
        conflictController: root.conflictController
        notificationController: root.notificationController
        statusController: root.statusController
    }

    ConflictPopup {
        id: cherryPickConflictPopup
        currentOperation: ConflictPopup.OperationType.CherryPick
        cherryPickController: root.cherryPickController
        conflictController: root.conflictController
        notificationController: root.notificationController
        statusController: root.statusController
    }

    CheckoutBranchSelectorPopup {
        id: checkoutBranchSelector
        property string commitHash: ""
        onBranchSelected: function(branchName) {
            root.handleCheckoutBranchOrCreate(branchName, checkoutBranchSelector.commitHash)
        }
    }

    /* Functions
     * ****************************************************************************************/
    function emptyStateDetailsText() {
        if (!root.allCommits || root.allCommits.length === 0)
            return "This repository has no commits."

        // 2) Commits exist, but filter/search returned no matches
        if (!root.hasAnyFilter)
            return "No commits to show."

        var parts = []

        var needle = (root.filterText || "").trim()
        if (needle.length > 0) {
            var scope = (root.navigationRule === "Author") ? "author" : "message"
            parts.push(scope + " contains '" + needle + "'")
        }

        var start = (root.filterStartDate || "").trim()
        var end = (root.filterEndDate || "").trim()
        if (start.length > 0 || end.length > 0) {
            if (start.length > 0 && end.length > 0)
                parts.push("date between " + start + " and " + end)
            else if (start.length > 0)
                parts.push("date from " + start)
            else
                parts.push("date until " + end)
        }

        if (parts.length === 0)
            return "No commits match your filter."

        return "No commits match: " + parts.join(", ")
    }

    function clearGraphCaches() {
        GraphUtils.clearBranchColorCache()
        GraphUtils.clearTagColorCache()
        GraphUtils.clearCategoryColorCache()
    }

    function layoutCommits(items) {
        return GraphLayout.calculateDAGPositions(items, root.columnSpacing, root.commitItemHeight, root.commitItemSpacing)
    }

    function applyFilter(text, startDate, endDate, modes) {
        if (text !== undefined)
            root.filterText = text

        if (startDate !== undefined)
            root.filterStartDate = startDate

        if (endDate !== undefined)
            root.filterEndDate = endDate

        if (modes !== undefined)
            root.filterMode = modes

        var result = Filter.applyFilter(
            root.allCommits,
            root.filterText,
            root.filterStartDate,
            root.filterEndDate,
            root.filterMode,
            root.selectedCommitHashes
        )

        loadData(result.filtered)
        root.selectedCommitHashes = result.stillSelected
        if (!result.stillSelected.length) {
            root.selectedCommit = null
            root.lastSelectedIndex = -1
        }

        if (Filter.hasAnyFilter(root.filterText, root.filterStartDate, root.filterEndDate)) {
            ensureMinimumResults()
        }
    }

    function clearFilter() {
        root.filterText         = ""
        root.filterStartDate    = ""
        root.filterEndDate      = ""
        root.filterMode         = []
        root.navigationRule     = "Message"
        loadData(root.allCommits.slice(0))
    }

    function loadData(items) {
        var positions = layoutCommits(items)
        assignLaneColorKeys(items, positions)
        root.commitPositions = positions
        root.commits = items.slice(0)
    }

    function assignLaneColorKeys(items, positions) {
        var colorKeyByHash = {}
        for (var i = items.length - 1; i >= 0; i--) {
            var c = items[i]
            var pos = positions[c.hash]
            if (!pos) continue

            var inherited = ""
            if (c.parentHashes && c.parentHashes.length) {
                for (var p = 0; p < c.parentHashes.length; p++) {
                    var parentHash = c.parentHashes[p]
                    var parentPos = positions[parentHash]
                    if (parentPos && parentPos.column === pos.column) {
                        inherited = colorKeyByHash[parentHash] || ""
                        break
                    }
                }
            }

            c.colorKey = inherited ? inherited : ("lane-seg:" + pos.column + ":" + c.hash)
            colorKeyByHash[c.hash] = c.colorKey
        }
    }

    function update() {
        graphCanvas.requestPaint()
    }

    function reloadAll() {
        if (!root.appModel || !root.appModel.currentRepository)
            return

        clearGraphCaches()
        commitsOffset   = 0
        hasMoreCommits  = true
        isLoadingMore   = false

        var headRes = root.statusController ? root.statusController.getHeadHash() : null
        root.headHash = (headRes && headRes.success) ? headRes.data : ""

        var commitRes = root.commitController.getCommits(pageSize, commitsOffset)
        if (!commitRes.success || !commitRes.data) return

        var page = commitRes.data
        var compiled = compilePage(page)

        var statusRes = root.statusController ? root.statusController.status() : null
        var uncommitted = DataLoader.createUncommittedNode(statusRes && statusRes.success ? statusRes.data : null, root.headHash)
        if (uncommitted) compiled.unshift(uncommitted)

        commitsOffset = page.length
        hasMoreCommits = (page.length === pageSize)

        root.allCommits = compiled.slice(0)
        root.applyFilter(root.filterText, root.filterStartDate, root.filterEndDate, root.filterMode)
    }

    /*!
     * Ensures that filtered results meet minimum threshold by loading more pages if needed.
     * Automatically loads additional pages until we have at least pageSize results or no more commits.
     */
    function ensureMinimumResults() {
        if (!Filter.hasAnyFilter(root.filterText, root.filterStartDate, root.filterEndDate))
            return

        if ((root.commits ? root.commits.length : 0) >= pageSize)
            return

        if (!hasMoreCommits || isLoadingMore)
            return

        loadMoreCommits()
    }

    /*!
     * Loads additional commits specifically for filter scenarios.
     * Continues loading until filtered results reach pageSize or no more commits available.
     */
    function loadMoreCommits() {
        if (isLoadingMore || !hasMoreCommits)
            return

        var currentContentY = commitsListView ? commitsListView.contentY : 0
        isLoadingMore = true

        var commitRes = root.commitController.getCommits(pageSize, commitsOffset)
        if (!commitRes.success || !commitRes.data) {
            isLoadingMore = false
            return
        }

        var page = commitRes.data
        if (!page.length) {
            hasMoreCommits = false
            isLoadingMore = false
            return
        }

        var compiled = compilePage(page)
        var withoutStashes = root.allCommits.filter(function(c) { return !c.isStash })
        root.allCommits = withoutStashes.concat(compiled)

        commitsOffset += page.length
        hasMoreCommits = (page.length === pageSize)

        root.applyFilter(root.filterText, root.filterStartDate, root.filterEndDate, root.filterMode)
        if (commitsListView) commitsListView.contentY = currentContentY

        isLoadingMore = false
    }

    function compilePage(page) {
        return DataLoader.compileGraphCommits(
            page,
            root.branchController ? root.branchController.getBranches() : [],
            getStashes(),
            getTags(),
            root.appModel && root.appModel.appSettings ? root.appModel.appSettings.generalSettings : null
        )
    }

    /**
     * Refreshes stash nodes in the existing commit list without re-fetching all commits.
     * Called when stashController becomes available after the initial load, or when
     * stashes change (save/pop/drop).
     */
    function refreshStashNodes() {
        if (!root.allCommits.length)
            return

        var baseCommits = root.allCommits.filter(function(c) { return !c.isStash })
        root.allCommits = DataLoader.compileGraphCommits(
            baseCommits,
            root.branchController ? root.branchController.getBranches() : [],
            getStashes(),
            getTags(),
            root.appModel && root.appModel.appSettings ? root.appModel.appSettings.generalSettings : null
        )

        root.applyFilter(root.filterText, root.filterStartDate, root.filterEndDate, root.filterMode)
    }

    function getTags() {
        if (!root.tagController)
            return
        var tagRes = root.tagController.list()
        if (!tagRes.success || !tagRes.data)
            return []

        return tagRes.data
    }

    function getStashes() {
        if (!root.stashController)
            return
        var stashRes = root.stashController.list()
        if (!stashRes.success || !stashRes.data)
            return []

        return stashRes.data
    }

    function isCommitSelected(hash) {
        return root.selectedCommitHashes && root.selectedCommitHashes.indexOf(hash) !== -1
    }

    function setSingleSelection(commitData, index) {
        root.selectedCommitHashes = [commitData.hash]
        root.lastSelectedIndex = index
    }

    function selectedCommitsInOrder() {
        var selected = []
        if (!root.commits || !root.selectedCommitHashes) return selected
        for (var i = root.commits.length - 1; i >= 0; i--) {
            var c = root.commits[i]
            if (c && c.hash && isCommitSelected(c.hash)) selected.push(c)
        }
        return selected
    }

    function handleItemClick(data, button, modifiers, idx, mouseX, mouseY) {
        if (!data)
            return

        root.selectedCommit = data
        root.commitClicked(data.isUncommitted ? "__uncommitted__" : data.hash)

        if (button === Qt.RightButton) {
            if (data.isUncommitted){
                root.selectedCommit = data;
                root.commitClicked("__uncommitted__");
                return;
            }

            if (!isCommitSelected(data.hash))
                setSingleSelection(data, idx)

            var state = getMenuState(data)
            var rawMenu = MenuBuilder.buildMenu(state)

            contextMenu.menuModel = buildContextMenuModel(rawMenu)

            contextMenu.x = mouseX
            contextMenu.y = mouseY
            contextMenu.open()
            return
        }

        if (data.isUncommitted) return
        var selection = Navigation.applySelection(data, idx, modifiers, root.selectedCommitHashes, root.lastSelectedIndex, root.commits)
        if (selection) {
            root.selectedCommitHashes = selection.hashes
            root.lastSelectedIndex = selection.lastIndex
        }
    }

    function getMenuState(commitData) {
        var branches        = commitData.branchNames || []
        var shortHash       = commitData.shortHash || commitData.hash.substring(0, 7)
        var isHead          = commitData.hash === root.headHash
        var currentBranch   = root.branchController.getCurrentBranchName()
        var mergeable       = branches.filter(function(b) { return b !== currentBranch && !b.startsWith("origin/") })

        return {
            currentBranch       : currentBranch,
            isHead              : isHead,
            shortHash           : shortHash,
            fullHash            : commitData.hash,
            branchNames         : branches,
            isStash             : commitData.isStash || false,
            canCherryPick       : !commitData.isStash && !isHead,
            canRebase           : !!currentBranch && !isHead,
            numSelected         : selectedCommitHashesInOrder().length,
            cherryPickEnabled   : !selectionHasStash() && !selectionHasHead(),
            hasMergeableBranches: mergeable.length > 0,
            mergeableBranches   : mergeable
        }
    }

    function selectedCommitHashesInOrder() {
        var selected = selectedCommitsInOrder()
        var hashes = []
        for (var i = 0; i < selected.length; i++) hashes.push(selected[i].hash)
        return hashes
    }

    function selectionHasStash() {
        var selected = selectedCommitsInOrder()
        for (var i = 0; i < selected.length; i++) if (selected[i].isStash) return true
        return false
    }

    function selectionHasHead() {
        var selected = selectedCommitsInOrder()
        for (var i = 0; i < selected.length; i++) if (selected[i].hash === root.headHash) return true
        return false
    }

    function buildContextMenuModel(raw) {
        return raw.map(function(item) {

            if (item.separator)
                return { separator: true }

            var result = {
                text    : item.text,
                icon    : resolveMenuIcon(item.icon),
                enabled : item.enabled !== false
            }

            if (item.subItems) {
                result.subItems = buildContextMenuModel(item.subItems)
            } else {
                result.action = function() {
                    root.executeMenuAction(item)
                }
            }

            return result
        })
    }

    function resolveMenuIcon(iconName) {
        switch (iconName) {

            case "gitBranch":
                return Style.icons.gitBranch

            case "hash":
                return Style.icons.hash

            case "branchPlus":
                return Style.icons.branchPlus

            case "tag":
                return Style.icons.tag

            case "arowLeftRight":
                return Style.icons.arowLeftRight

            case "clockRotateLeft":
                return Style.icons.clockRotateLeft

            case "copy":
                return Style.icons.copy

            default: return ""
        }
    }

    function executeMenuAction(item) {
        switch (item.action) {

        case "checkoutBranch":
            executeCheckoutBranch(item.payload.branch)
            break

        case "checkoutCommit":
            executeCheckoutCommit(item.payload.hash)
            break

        case "newBranch":
            executeNewBranch(item.payload.hash)
            break

        case "newTag":
            executeNewTag(item.payload.hash)
            break

        case "mergeBranch":
            executeMergeBranch(item.payload.source, item.payload.target)
            break

        case "rebase":
            executeRebase(item.payload.hash)
            break
        case "cherryPickSelected":
            executeCherryPickSelected()
            break

        case "cherryPickSingle":
            executeCherryPickSingle(item.payload.hash)
            break
        }
    }

    function executeCheckoutBranch(branchName) {
        handleContextResponse(root.branchController.checkoutBranch(branchName), "Checked out branch " + branchName)
    }

    function executeCheckoutCommit(commitHash) {
        handleContextResponse(root.branchController.checkoutCommit(commitHash), "Checked out commit " + commitHash.substring(0, 7))
    }

    function executeNewBranch(commitHash) {
        if (!root.addBranchPopup)
            return

        root.addBranchPopup.branchController    = root.branchController
        root.addBranchPopup.targetHash          = commitHash
        root.addBranchPopup.open()
    }

    function executeNewTag(commitHash) {
        if (!root.addTagPopup)
            return

        root.addTagPopup.tagController  = root.tagController || null
        root.addTagPopup.targetHash     = commitHash
        root.addTagPopup.open()
    }

    function executeMergeBranch(source, target) {
        mergeMethodPopup.sourceBranch = source
        mergeMethodPopup.targetBranch = target

        mergeMethodPopup.accepted.connect(function(noFF) {
            var res = root.mergeController.mergeBranchIntoCurrent(source, noFF)

            if (root.mergeController.hasMergeConflicts()) {
                mergeConflictPopup.open()

                root.notificationController.warning("Merge conflicts detected.", "Merge", 4000)

                root.reloadAll()
            } else {
                handleGitControllerResult(res, "Merge completed", mergeConflictPopup, "Merge")
            }

            mergeMethodPopup.accepted.disconnect(arguments.callee)
        })

        mergeMethodPopup.open()
    }

    function executeRebase(commitHash) {
        var res = rebaseController.rebase(commitHash);

        handleGitControllerResult(res, "Rebase completed", rebaseConflictPopup, "Rebase");
    }

    function executeCherryPickSelected() {
        var hashes  = selectedCommitHashesInOrder();
        var res     = cherryPickController.cherryPickCommits(hashes);

        handleGitControllerResult(res, "Cherry-pick completed", cherryPickConflictPopup, "Cherry-Pick");
    }

    function executeCherryPickSingle(commitHash) {
        var res = cherryPickController.cherryPickCommit(commitHash);

        handleGitControllerResult(res, "Cherry-pick completed", cherryPickConflictPopup, "Cherry-Pick");
    }

    function handleGitControllerResult(res, successMsg, conflictPopup, commandName) {
        if (res && res.success) {
            notificationController.success(successMsg, commandName, 3000)
        }
        else if (res && res.data && (res.data.status === "conflict" || res.data.hasConflicts)) {
            conflictPopup.open();
            notificationController.warning(commandName + " conflicts detected.", commandName, 4000);
        }
        else {
            notificationController.error(res ? res.errorMessage : commandName + " failed", commandName, 5000);
        }

        root.reloadAll();
    }

    function handleItemDoubleClick(data, button, modifiers, idx) {
        if (button !== Qt.LeftButton || !data)
            return

        if (data.isUncommitted || data.isStash || data.hash === root.headHash)
            return

        var branches    = data.branchNames || []
        var shortHash   = data.shortHash || data.hash.substring(0, 7)

        if (!branches.length) {
            var checkoutCommitRes = root.branchController.checkoutCommit(data.hash)
            handleContextResponse(checkoutCommitRes, "Checked out commit " + shortHash)
            return
        }

        var allBranches = root.branchController.getBranches()
        var localNames  = {}
        for (var i = 0; i < allBranches.length; i++) {
            var b = allBranches[i]
            if (b && b.isLocal) localNames[b.name] = true
        }

        var seen = {}
        var deduped = []
        for (var j = 0; j < branches.length; j++) {
            var name = branches[j]
            var base = name.replace(/^[^/]+\//, "")
            if (!seen[base]) {
                seen[base] = true
                deduped.push(localNames[base] ? base : name)
            }
        }

        if (deduped.length === 1) {
            handleCheckoutBranchOrCreate(deduped[0], data.hash)
        } else {
            checkoutBranchSelector.commitHash = data.hash
            checkoutBranchSelector.branches = deduped
            checkoutBranchSelector.open()
        }
    }

    function handleCheckoutBranchOrCreate(branchName, commitHash) {
        var allBranches = root.branchController.getBranches()
        var localNames  = {}
        for (var i = 0; i < allBranches.length; i++) {
            var b = allBranches[i]
            if (b && b.isLocal) localNames[b.name] = true
        }

        if (localNames[branchName]) {
            handleContextResponse(root.branchController.checkoutBranch(branchName), "Checked out branch " + branchName)
            return
        }

        var localName = branchName.replace(/^[^/]+\//, "")
        var createRes = root.branchController.createBranch(commitHash, localName)
        if (!createRes.success) {
            handleContextResponse(createRes, "")
            return
        }

        handleContextResponse(root.branchController.checkoutBranch(localName), "Created and checked out branch " + localName)
    }

    function handleContextResponse(res, successMsg) {
        if (res && res.success)
            root.notificationController.success(successMsg, "Checkout", 3000)

        else
            root.notificationController.error(res ? (res.errorMessage || "Operation failed") : "Operation failed", "Operation Error", 5000)

        root.selectedCommit = null
        root.selectedCommitHashes = []
        root.lastSelectedIndex = -1
        root.reloadAll()
    }

    function selectNext(rule) {
        var idx     = Navigation.selectedIndex(root.commits, root.selectedCommit)
        var result  = Navigation.selectNext(root.commits, root.selectedCommit, idx, root.navigationRule, rule)

        if (!result)
            return

        if (rule !== undefined)
            root.navigationRule = rule

        setSingleSelection(result.selected, result.index)
        root.selectedCommit = result.selected
        root.commitClicked(result.selected.hash)

        if (result.scroll)
            commitsListView.positionViewAtIndex(result.index, ListView.Contain)
    }

    function selectPrevious(rule) {
        var idx     = Navigation.selectedIndex(root.commits, root.selectedCommit)
        var result  = Navigation.selectPrevious(root.commits, root.selectedCommit, idx, root.navigationRule, rule)

        if (!result)
            return

        if (rule !== undefined)
            root.navigationRule = rule

        setSingleSelection(result.selected, result.index)
        root.selectedCommit = result.selected
        root.commitClicked(result.selected.hash)

        if (result.scroll)
            commitsListView.positionViewAtIndex(result.index, ListView.Contain)
    }
}
