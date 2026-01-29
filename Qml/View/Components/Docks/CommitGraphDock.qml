import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

import "qrc:/GitEase/Qml/Core/Scripts/GraphUtils.js" as GraphUtils


/*! ***********************************************************************************************
 * CommitGraphDock
 * show graph and commits using separate GraphView and CommitsListView components
 * ************************************************************************************************/
Item {

    id : root

    property AppModel             appModel:             null

    property BranchController     branchController:     null

    property CommitController     commitController:     null

    property RepositoryController repositoryController: null

    /* Property Declarations
     * ****************************************************************************************/
    // Full data set (unfiltered) vs displayed set (filtered)
    property var    allCommits:         []
    property var    commits:            []
    property string selectedCommitHash: ""
    property string hoveredCommitHash:  ""
    property var    allCommitsHash:     ({})

    // navigation state
    // navigationRule: one of ["Author Email", "Author", "Parent 1", "Branch"]
    property string navigationRule:     "Message"
    // Dates are inclusive; accept empty string to disable bound. Format: YYYY-MM-DD
    property string filterStartDate:    ""
    property string filterEndDate:      ""
    property string filterText:         ""
    property var    filterMode:         []  // Array of selected filter items: ["Messages", "Authors", etc.]

    // Empty-state helper
    readonly property bool hasAnyFilter: (root.filterText && root.filterText.trim().length > 0)
                                          || (root.filterStartDate && root.filterStartDate.trim().length > 0)
                                          || (root.filterEndDate && root.filterEndDate.trim().length > 0)

    // Lazy loading (infinite scroll)
    property int  pageSize:          200
    property int  commitsOffset:     0
    property bool isLoadingMore:     false
    property bool hasMoreCommits:    true

    property int  graphColumnWidth:  0   // Will be calculated as half of dock width
    property int  commitItemHeight:  24  // Reduced spacing between commits
    property int  commitItemSpacing: 4
    property int  columnSpacing:     30  // Increased spacing between branch columns

    // Property to receive list of CommitData objects
    property int commitsColGraphWidth:     parent.width * 0.07
    property int commitsColBranchTagWidth: parent.width * 0.15
    property int commitsColMessageWidth:   parent.width * 0.55
    property int commitsColAuthorWidth:    parent.width * 0.08
    property int commitsColDateWidth:      parent.width * 0.15
    
    // Minimum widths for each column
    readonly property int minColGraphWidth:     60
    readonly property int minColBranchTagWidth: 80
    readonly property int minColMessageWidth:   100
    readonly property int minColAuthorWidth:    60
    readonly property int minColDateWidth:      80

    /* Signals
     * ****************************************************************************************/
    signal commitClicked(string commitId)

    /* Functions
     * ****************************************************************************************/
    function emptyStateDetailsText() {
        // 1) No commits in repo at all
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

    function normalizeFilterString(str) {
        return (str === null || str === undefined) ? "" : ("" + str)
    }

    /*!
     * Application-level filter: checks if a commit matches based on selected filter modes
     * Returns true if the commit matches the filter criteria
     */
    function applicationFilter(commit, needle, modes) {
        if (!needle || needle.length === 0)
            return true  // No text filter, matches all

        // If no modes selected, default to "Messages"
        var activeMode = (modes && modes.length > 0) ? modes : ["Messages"]
        
        // Check each active filter mode
        for (var i = 0; i < activeMode.length; i++) {
            var mode = activeMode[i]
            var haystack = ""
            
            switch(mode) {
                case "Messages":
                    haystack = normalizeFilterString(commit.summary) + " " + normalizeFilterString(commit.message)
                    break
                case "Subjects":
                    haystack = normalizeFilterString(commit.summary)
                    break
                case "Authors":
                    haystack = normalizeFilterString(commit.author)
                    break
                case "Emails":
                    haystack = normalizeFilterString(commit.authorEmail)
                    break
                case "SHA-1":
                    haystack = normalizeFilterString(commit.hash)
                    break
                default:
                    continue
            }
            
            // If any mode matches, return true
            if (haystack.toLowerCase().indexOf(needle) !== -1)
                return true
        }
        
        return false  // No mode matched
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

        var base = root.allCommits || []
        if (!base.length) {
            loadData([])
            return
        }

        var needle = normalizeFilterString(root.filterText).trim().toLowerCase()

        var startMs = GraphUtils.parseDateYYYYMMDD(root.filterStartDate)
        var endMs = GraphUtils.parseDateYYYYMMDD(root.filterEndDate)

        if (!isNaN(endMs))
            endMs = endMs + (24 * 60 * 60 * 1000) - 1

        var filtered = []
        for (var i = 0; i < base.length; i++) {
            var c = base[i]
            if (!c)
                continue

            // Date range filter (authorDate)
            if (!isNaN(startMs) || !isNaN(endMs)) {
                var commitMs = new Date(c.authorDate).getTime()
                if (!isNaN(startMs) && !(commitMs >= startMs))
                    continue
                if (!isNaN(endMs) && !(commitMs <= endMs))
                    continue
            }

            // Text filter using applicationFilter
            if (!applicationFilter(c, needle, root.filterMode))
                continue

            filtered.push(c)
        }

        loadData(filtered)

        // Auto-load more pages if filtered results are less than pageSize
        ensureMinimumResults()

        // If current selection is filtered out, clear it.
        if (root.selectedCommitHash && root.selectedCommitHash.length > 0) {
            var stillThere = filtered.find(function(x) { return x && x.hash === root.selectedCommitHash })
            if (!stillThere)
                root.selectedCommitHash = ""
        }
    }

    /*!
     * Ensures that filtered results meet minimum threshold by loading more pages if needed.
     * Automatically loads additional pages until we have at least pageSize results or no more commits.
     */
    function ensureMinimumResults() {
        if (!root.hasAnyFilter) {
            return
        }

        var currentResultCount = root.commits ? root.commits.length : 0
        
        if (currentResultCount >= root.pageSize || !root.hasMoreCommits || root.isLoadingMore) {
            return
        }

        loadMoreCommitsForFilter()
    }

    /*!
     * Loads additional commits specifically for filter scenarios.
     * Continues loading until filtered results reach pageSize or no more commits available.
     */
    function loadMoreCommitsForFilter() {
        if (root.isLoadingMore || !root.hasMoreCommits) {
            return
        }

        root.isLoadingMore = true

        var allBranches = branchController.getBranches();
        let page = commitController.getCommits(pageSize, commitsOffset);
        
        if (!page || page.length === 0) {
            root.hasMoreCommits = false
            root.isLoadingMore = false
            return
        }

        var compiled = compileGraphCommits(page, allBranches);
        var commits = root.allCommits.concat(compiled)
        root.commitsOffset = commits.length
        root.hasMoreCommits = (page.length === root.pageSize)

        root.allCommits = commits.slice(0)
        
        var currentText = root.filterText
        var currentStartDate = root.filterStartDate
        var currentEndDate = root.filterEndDate
        var currentModes = root.filterMode
        
        root.isLoadingMore = false
        
        root.applyFilter(currentText, currentStartDate, currentEndDate, currentModes)
    }

    function clearFilter() {
        root.filterText = ""
        root.filterStartDate = ""
        root.filterEndDate = ""
        root.navigationRule = "Message"

        loadData((root.allCommits || []).slice(0))
    }

    /**
     * Build a branch membership map without modifying original commit.branchNames
     * Returns: { commitHash: [branchName1, branchName2, ...] }
     */
    function buildBranchMembershipMap(commits) {
        // Build a hash lookup for fast access
        var commitByHash = {}
        for (var i = 0; i < commits.length; i++) {
            commitByHash[commits[i].hash] = commits[i]
        }

        // Initialize membership map with original branch names (tips only)
        var membershipMap = {}
        for (var i = 0; i < commits.length; i++) {
            var commit = commits[i]
            if (commit.branchNames && commit.branchNames.length > 0) {
                membershipMap[commit.hash] = commit.branchNames.slice() // Copy array
            }
        }

        // Propagate branch membership from children to parents
        // Process from newest to oldest (top to bottom)
        for (var i = 0; i < commits.length; i++) {
            var commit = commits[i]
            var commitBranches = membershipMap[commit.hash]
            
            // If this commit has branch membership, propagate to parents
            if (commitBranches && commitBranches.length > 0) {
                // Propagate to first parent (main lineage)
                if (commit.parentHashes && commit.parentHashes.length > 0) {
                    var firstParentHash = commit.parentHashes[0]
                    var parent = commitByHash[firstParentHash]
                    
                    if (parent) {
                        // Initialize parent's branch list if not exists
                        if (!membershipMap[firstParentHash]) {
                            membershipMap[firstParentHash] = []
                        }
                        
                        // Add branches to parent if not already present
                        for (var b = 0; b < commitBranches.length; b++) {
                            var branchName = commitBranches[b]
                            if (membershipMap[firstParentHash].indexOf(branchName) === -1) {
                                membershipMap[firstParentHash].push(branchName)
                            }
                        }
                    }
                }
            }
        }
        
        return membershipMap
    }

    /**
     * Load commit data and assign colors based on branch names
     */
    function loadData(commits) {
        // Build branch membership map (doesn't modify original commits)
        var branchMembership = buildBranchMembershipMap(commits)
        
        // Color assignment based on branch membership
        // Strategy: Use primary branch name as the color key
        // For commits on the same branch lineage, they'll inherit the same color
        var colorKeyByHash = {}

        for (var j = commits.length - 1; j >= 0; j--) {
            var commit = commits[j]
            
            // Determine primary branch for this commit
            var primaryBranch = "main" // Default fallback
            var commitBranches = branchMembership[commit.hash]
            if (commitBranches && commitBranches.length > 0) {
                primaryBranch = commitBranches[0]
            }

            // Try to inherit color from parent if on the same branch
            var inheritedKey = ""
            if (commit.parentHashes && commit.parentHashes.length > 0) {
                // Check first parent (main lineage)
                var firstParentHash = commit.parentHashes[0]
                var parentColorKey = colorKeyByHash[firstParentHash]
                
                if (parentColorKey) {
                    // Extract branch from parent's color key
                    var parentBranch = parentColorKey.replace("branch:", "")
                    
                    // Inherit if on same branch
                    if (parentBranch === primaryBranch) {
                        inheritedKey = parentColorKey
                    }
                }
            }

            if (inheritedKey) {
                commit.colorKey = inheritedKey
            } else {
                // Create new color key for this branch
                commit.colorKey = "branch:" + primaryBranch
            }

            colorKeyByHash[commit.hash] = commit.colorKey
        }

        root.commits = commits.slice(0)
    }

    /* Children
     * ****************************************************************************************/
    Rectangle{
        anchors.fill: parent
        color : Style.colors.primaryBackground

        RowLayout {
            anchors.fill: parent
            spacing: 0

            // Graph View Component
            GraphView {
                id: graphView

                Layout.fillWidth: false
                Layout.preferredWidth: root.commitsColGraphWidth + root.commitsColBranchTagWidth
                Layout.fillHeight: true
                Layout.minimumWidth: root.minColGraphWidth + root.minColBranchTagWidth

                commits: root.commits

                selectedCommitHash: root.selectedCommitHash
                hoveredCommitHash: root.hoveredCommitHash

                showAvatar: root.appModel?.appSettings?.generalSettings?.showAvatar ?? true

                commitItemHeight: root.commitItemHeight
                commitItemSpacing: root.commitItemSpacing
                columnSpacing: root.columnSpacing

                emptyStateDetailsText: root.emptyStateDetailsText()

                graphWidth: root.commitsColGraphWidth
                branchTagWidth: root.commitsColBranchTagWidth

                onScrollPositionChanged: function(contentY, contentHeight, height) {
                    // Infinite scroll trigger (graph side)
                    if (!root.isLoadingMore && root.hasMoreCommits) {
                        var remaining = contentHeight - (contentY + height)
                        if (remaining < 300) {
                            root.loadMoreCommits()
                        }
                    }

                    // Sync with commits list - use absolute position, not ratio
                    commitsListView.setContentY(contentY)
                }

                onGraphWidthResized: function(newGraphWidth, newBranchTagWidth) {
                    root.commitsColGraphWidth = newGraphWidth
                    root.commitsColBranchTagWidth = newBranchTagWidth
                }

                onCommitSelected: function(commitHash) {
                    root.selectedCommitHash = commitHash
                    root.commitClicked(commitHash)
                }

                onCommitHovered: function(commitHash) {
                    root.hoveredCommitHash = commitHash
                }
            }

            // Resizable divider between GraphView and CommitsListView
            Rectangle {
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                color: mainDividerMouseArea.containsMouse || mainDividerMouseArea.pressed ? 
                       Style.colors.resizeHandlePressed : Style.colors.resizeHandle

                MouseArea {
                    id: mainDividerMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.SizeHorCursor

                    property real startX: 0
                    property int startGraphWidth: 0

                    onPressed: function(mouse) {
                        startX = mouseX + mapToItem(root, 0, 0).x
                        startGraphWidth = root.commitsColGraphWidth + root.commitsColBranchTagWidth
                    }

                    onPositionChanged: function(mouse) {
                        if (!pressed) return

                        var currentX = mouseX + mapToItem(root, 0, 0).x
                        var delta = currentX - startX
                        
                        var newGraphViewWidth = startGraphWidth + delta
                        var minGraphViewWidth = root.minColGraphWidth + root.minColBranchTagWidth
                        var minCommitsViewWidth = root.minColMessageWidth + root.minColAuthorWidth + root.minColDateWidth
                        
                        // Ensure minimum widths
                        if (newGraphViewWidth < minGraphViewWidth) {
                            newGraphViewWidth = minGraphViewWidth
                        }
                        
                        var availableWidth = root.width
                        var newCommitsViewWidth = availableWidth - newGraphViewWidth - 5 // 5 for divider
                        
                        if (newCommitsViewWidth < minCommitsViewWidth) {
                            newCommitsViewWidth = minCommitsViewWidth
                            newGraphViewWidth = availableWidth - newCommitsViewWidth - 5
                        }
                        
                        // Calculate percentages
                        var graphViewPercent = newGraphViewWidth / availableWidth
                        var commitsViewPercent = newCommitsViewWidth / availableWidth
                        
                        // Update GraphView columns (maintaining internal ratio)
                        var currentGraphRatio = root.commitsColGraphWidth / (root.commitsColGraphWidth + root.commitsColBranchTagWidth)
                        root.commitsColGraphWidth = newGraphViewWidth * currentGraphRatio
                        root.commitsColBranchTagWidth = newGraphViewWidth * (1 - currentGraphRatio)
                        
                        // Update CommitsListView columns (maintaining internal ratios)
                        var totalCommitsWidth = root.commitsColMessageWidth + root.commitsColAuthorWidth + root.commitsColDateWidth
                        var messageRatio = root.commitsColMessageWidth / totalCommitsWidth
                        var authorRatio = root.commitsColAuthorWidth / totalCommitsWidth
                        var dateRatio = root.commitsColDateWidth / totalCommitsWidth
                        
                        root.commitsColMessageWidth = newCommitsViewWidth * messageRatio
                        root.commitsColAuthorWidth = newCommitsViewWidth * authorRatio
                        root.commitsColDateWidth = newCommitsViewWidth * dateRatio
                    }
                }
            }

            // Commits List View Component
            CommitsListView {
                id: commitsListView
                Layout.fillWidth: true
                Layout.fillHeight: true

                commits: root.commits
                selectedCommitHash: root.selectedCommitHash
                hoveredCommitHash: root.hoveredCommitHash

                commitItemHeight: root.commitItemHeight
                commitItemSpacing: root.commitItemSpacing

                messageWidth: root.commitsColMessageWidth
                authorWidth: root.commitsColAuthorWidth
                dateWidth: root.commitsColDateWidth

                emptyStateDetailsText: root.emptyStateDetailsText()


                property bool syncScroll: false

                onCommitSelected: function(commitHash) {
                    root.selectedCommitHash = commitHash
                    root.commitClicked(commitHash)
                }

                onCommitHovered: function(commitHash) {
                    root.hoveredCommitHash = commitHash
                }

                onScrollPositionChanged: function(contentY, contentHeight, height) {
                    if (syncScroll) return

                    // Infinite scroll trigger (list side)
                    if (!root.isLoadingMore && root.hasMoreCommits) {
                        var remaining = contentHeight - (contentY + height)
                        if (remaining < 300) {
                            root.loadMoreCommits()
                        }
                    }

                    // Sync with graph - use absolute position, not ratio
                    graphView.setContentY(contentY)
                }

                onColumnWidthResized: function(newMessageWidth, newAuthorWidth, newDateWidth) {
                    root.commitsColMessageWidth = newMessageWidth
                    root.commitsColAuthorWidth = newAuthorWidth
                    root.commitsColDateWidth = newDateWidth
                }
            }
        }
    }

    // Connections for theme changes and other updates
    Connections {
        target: Style
        function onCurrentThemeChanged(){
            graphView.requestPaint()
        }
    }

    Connections {
        target: appModel?.appSettings?.generalSettings ?? null
        function onShowAvatarChanged() {
            graphView.requestPaint()
        }
    }

    /**
     * Load all commits from repository
     */
    // Build graph-ready commits by combining:
    // - getCommits(): list of commits (hash, summary, author, ...)
    // - getCommit(hash): per-commit details (parentHashes, etc)
    // - getBranches(): to attach branch name labels to tip commits (targetHash)
    function compileGraphCommits(rawCommits, rawBranches) {
        if (!rawCommits) return []

        // tip commit hash -> [branchName,...]
        var tipHashToBranches = {}
        var branchTipHashes = []
        if (rawBranches && rawBranches.length) {
            for (var i = 0; i < rawBranches.length; i++) {
                var b = rawBranches[i]
                if (!b || !b.targetHash) continue
                if (!tipHashToBranches[b.targetHash]) {
                    tipHashToBranches[b.targetHash] = []
                    branchTipHashes.push(b.targetHash)
                }
                tipHashToBranches[b.targetHash].push(b.name)
            }
        }

        // Build commits
        var compiled = []

        for (var c = 0; c < rawCommits.length; c++) {
            var commit = rawCommits[c]

            var obj = {
                hash: commit.hash,
                shortHash: commit.shortHash,
                message: commit.message,
                summary: commit.summary,
                author: commit.author,
                authorEmail: commit.authorEmail,
                authorDate: commit.authorDate,

                parentHashes: commit.parentHashes,
                commitType: (commit.parentHashes.length > 1) ? "merge" : "normal",

                // Only branch tips start with branch names; we'll propagate membership below
                branchNames: tipHashToBranches[commit.hash] || [],
                tagNames: [],

                // assigned in loadData() after layout (lane -> category)
                colorKey: ""
            }

            compiled.push(obj)
        }

        return compiled
    }

    function selectedIndex() {
        if (!root.selectedCommit || !root.selectedCommit.hash)
            return -1

        for (var i = 0; i < root.commits.length; i++) {
            if (root.commits[i] && root.commits[i].hash === root.selectedCommit.hash)
                return i
        }
        return -1
    }

    function selectCommitAtIndex(index) {
        if (!root.commits || root.commits.length === 0)
            return

        var i = Math.max(0, Math.min(index, root.commits.length - 1))
        var c = root.commits[i]
        if (!c)
            return

        root.selectedCommit = c
        root.commitClicked(c.hash)
    }

    function selectPrevious(navigationRule) {
        if (navigationRule !== undefined)
            root.navigationRule = navigationRule
        
        if (!root.commits || root.commits.length === 0)
            return

        var idx = selectedIndex()
        if (idx < 0) {
            selectCommitAtIndex(0)
            return
        }

        var currentCommit = root.selectedCommit
        if (!currentCommit)
            return

        if (root.navigationRule === "Parent 1") {
            for (var i = idx - 1; i >= 0; i--) {
                var commit = root.commits[i]
                if (commit && commit.parentHashes && commit.parentHashes.length > 0) {
                    if (commit.parentHashes[0] === currentCommit.hash) {
                        selectCommitAtIndex(i)
                        return
                    }
                }
            }
            return
        }

        if (root.navigationRule === "Branch") {
            var laneKey = currentCommit.colorKey
            if (!laneKey)
                return

            for (var i = idx - 1; i >= 0; i--) {
                var commit = root.commits[i]
                if (commit && commit.colorKey === laneKey) {
                    selectCommitAtIndex(i)
                    return
                }
            }
            return
        }

        var matchValue = getNavigationRuleValue(currentCommit, root.navigationRule)
        
        for (var i = idx - 1; i >= 0; i--) {
            var commit = root.commits[i]
            if (commit && getNavigationRuleValue(commit, root.navigationRule) === matchValue) {
                selectCommitAtIndex(i)
                return
            }
        }
    }

    function selectNext(navigationRule) {
        if (navigationRule !== undefined)
            root.navigationRule = navigationRule
        
        if (!root.commits || root.commits.length === 0)
            return

        var idx = selectedIndex()
        if (idx < 0) {
            selectCommitAtIndex(0)
            return
        }

        var currentCommit = root.selectedCommit
        if (!currentCommit)
            return

        if (root.navigationRule === "Parent 1") {
            if (!currentCommit.parentHashes || currentCommit.parentHashes.length === 0) {
                return
            }
            
            var parentHash = currentCommit.parentHashes[0]
            
            for (var i = idx + 1; i < root.commits.length; i++) {
                var commit = root.commits[i]
                if (commit && commit.hash === parentHash) {
                    selectCommitAtIndex(i)
                    return
                }
            }
            return
        }

        if (root.navigationRule === "Branch") {
            var laneKey = currentCommit.colorKey
            if (!laneKey)
                return

            for (var i = idx + 1; i < root.commits.length; i++) {
                var commit = root.commits[i]
                if (commit && commit.colorKey === laneKey) {
                    selectCommitAtIndex(i)
                    return
                }
            }
            return
        }

        var matchValue = getNavigationRuleValue(currentCommit, root.navigationRule)
        
        for (var i = idx + 1; i < root.commits.length; i++) {
            var commit = root.commits[i]
            if (commit && getNavigationRuleValue(commit, root.navigationRule) === matchValue) {
                selectCommitAtIndex(i)
                return
            }
        }
    }

    /*!
     * Helper function to extract the value from a commit based on the navigation rule
     */
    function getNavigationRuleValue(commit, rule) {
        if (!commit)
            return null
        
        switch(rule) {
            case "Author":
                return normalizeFilterString(commit.author)
            case "Author Email":
                return normalizeFilterString(commit.authorEmail)
            case "Parent 1":
                // For Parent 1, return the first parent hash
                return (commit.parentHashes && commit.parentHashes.length > 0) 
                    ? commit.parentHashes[0] 
                    : null
            case "Branch":
                return commit.colorKey
            case "Message":
            default:
                return normalizeFilterString(commit.summary)
        }
    }

    function reloadAll() {
        if (!commitController || !branchController || !root.appModel || !root.appModel.currentRepository) {
            return;
        }

        commitsOffset = 0
        hasMoreCommits = true
        isLoadingMore = false

        let allBranches = branchController.getBranches();
        let commitRes = commitController.getCommits(pageSize, commitsOffset);

        if (!commitRes.success)
            return;
        let page = commitRes.data;

        var commits = compileGraphCommits(page, allBranches);
        commitsOffset = commits.length
        hasMoreCommits = (page && page.length === pageSize)

        // Store full dataset and apply current filter
        root.allCommits = commits.slice(0)
        root.applyFilter(root.filterText, root.filterStartDate, root.filterEndDate)
    }

    function loadMoreCommits() {
        if (isLoadingMore || !hasMoreCommits)
            return
        if (!branchController || !root.appModel || !root.appModel.currentRepository)
            return

        isLoadingMore = true

        let allBranches = branchController.getBranches();
        let commitRes = commitController.getCommits(pageSize, commitsOffset);

        if (!commitRes.success)
            return;
        let page = commitRes.data;
        if (!page || page.length === 0) {
            hasMoreCommits = false
            isLoadingMore = false
            return
        }

        var compiled = compileGraphCommits(page, allBranches);

        var commits = root.allCommits.concat(compiled)
        commitsOffset = commits.length
        hasMoreCommits = (page.length === pageSize)

        root.allCommits = commits.slice(0)
        root.applyFilter(root.filterText, root.filterStartDate, root.filterEndDate)

        isLoadingMore = false
    }

    onRepositoryControllerChanged: reloadAll();

    onCommitsChanged : graphView.requestPaint()

    onSelectedCommitHashChanged : graphView.requestPaint()

    onAllCommitsChanged: {
        root.allCommitsHash = {}
        for(let i = 0 ; i < root.allCommits.length; ++i)
            root.allCommitsHash[root.allCommits[i].hash] = root.allCommits[i].hash
    }

    Connections {
        target: repositoryController
        function onRepositorySelected(repo) {
            reloadAll();
        }
    }

    Connections {
        target: appModel?.appSettings?.generalSettings ?? null
        function onShowAvatarChanged() {
            graphView.requestPaint()
        }
    }
}
