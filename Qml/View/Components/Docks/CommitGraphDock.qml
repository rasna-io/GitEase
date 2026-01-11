import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

import "qrc:/GitEase/Qml/Core/Scripts/GraphLayout.js" as GraphLayout
import "qrc:/GitEase/Qml/Core/Scripts/GraphUtils.js" as GraphUtils


/*! ***********************************************************************************************
 * CommitGraphDock
 * show graph and commits
 * ************************************************************************************************/
Item {

    id : root

    property AppModel appModel: null

    property BranchController branchController: null

    property CommitController commitController: null

    property RepositoryController repositoryController: null

    /* Property Declarations
     * ****************************************************************************************/
    // Full data set (unfiltered) vs displayed set (filtered)
    property var allCommits: []
    property var commits: []
    property var selectedCommit: null

    // navigation state
    // navigationRule: one of ["Author Email", "Author", "Parent 1", "Branch"]
    property string navigationRule: "Message"
    // Dates are inclusive; accept empty string to disable bound. Format: YYYY-MM-DD
    property string filterStartDate: ""
    property string filterEndDate: ""
    property string filterText: ""
    property var filterMode: []  // Array of selected filter items: ["Messages", "Authors", etc.]

    // Empty-state helper
    readonly property bool hasAnyFilter: (root.filterText && root.filterText.trim().length > 0)
                                          || (root.filterStartDate && root.filterStartDate.trim().length > 0)
                                          || (root.filterEndDate && root.filterEndDate.trim().length > 0)

    // Lazy loading (infinite scroll)
    property int pageSize: 200
    property int commitsOffset: 0
    property bool isLoadingMore: false
    property bool hasMoreCommits: true

    property int graphColumnWidth: 0  // Will be calculated as half of dock width
    property int commitItemHeight: 24  // Reduced spacing between commits
    property int commitItemSpacing: 4
    property int columnSpacing: 30  // Increased spacing between branch columns
    property var commitPositions: ({})  // Cache for commit positions {hash: {x, y, column}}

    // Property to receive list of CommitData objects
    property int commitsColGraphWidth: parent.width * 0.08
    property int commitsColBranchTagWidth: parent.width * 0.17
    property int commitsColMessageWidth: parent.width * 0.6
    property int commitsColAuthorWidth: parent.width * 0.08
    property int commitsColDateWidth: parent.width * 0.17
    
    // Minimum widths for each column
    readonly property int minColGraphWidth: 60
    readonly property int minColBranchTagWidth: 80
    readonly property int minColMessageWidth: 100
    readonly property int minColAuthorWidth: 60
    readonly property int minColDateWidth: 80

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

    function commitColor(commitObj) {
        if (!commitObj || !commitObj.colorKey)
            return GraphUtils.getCategoryColor("default")
        return GraphUtils.getCategoryColor(commitObj.colorKey)
    }

    function edgeColor(edge, commitByHash) {
        if (commitByHash && edge && edge.from) {
            var fromCommit = commitByHash[edge.from]
            if (fromCommit && fromCommit.colorKey)
                return GraphUtils.getCategoryColor(fromCommit.colorKey)
        }
        return GraphUtils.getCategoryColor("edge:" + edge.from + ":" + edge.to)
    }

    function normalizeFilterString(str) {
        return (str === null || str === undefined) ? "" : ("" + str)
    }

    function parseDateYYYYMMDD(str) {
        // Returns milliseconds since epoch, or NaN if invalid.
        // Accepts:
        // - YYYY-MM-DD
        // - YYYY/MM/DD (used by GraphViewPage placeholders)
        if (str === null || str === undefined)
            return NaN

        str = ("" + str).trim()
        if (str.length < 8)
            return NaN

        // Split on '-' or '/'
        var parts = str.split(/[-\/]/)
        if (parts.length !== 3)
            return NaN

        var y = parseInt(parts[0])
        var m = parseInt(parts[1])
        var d = parseInt(parts[2])
        if (isNaN(y) || isNaN(m) || isNaN(d))
            return NaN

        // local time midnight
        return new Date(y, m - 1, d, 0, 0, 0, 0).getTime()
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

        var startMs = parseDateYYYYMMDD(root.filterStartDate)
        var endMs = parseDateYYYYMMDD(root.filterEndDate)

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
        if (root.selectedCommit && root.selectedCommit.hash) {
            var stillThere = filtered.find(function(x) { return x && x.hash === root.selectedCommit.hash })
            if (!stillThere)
                root.selectedCommit = null
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

        var allBranches = repositoryController.getBranches(repositoryController.appModel.currentRepository);
        var page = repositoryController.getCommits(repositoryController.appModel.currentRepository, root.pageSize, root.commitsOffset);
        
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
     * Load commit data and calculate graph layout positions
     */
    function loadData(commits) {
        commitPositions = GraphLayout.calculateDAGPositions(
            commits,
            root.columnSpacing,
            root.commitItemHeight,
            root.commitItemSpacing
        );

        // Color assignment:
        var colorKeyByHash = {}

        for (var j = commits.length - 1; j >= 0; j--) {
            var c2 = commits[j]
            var pos2 = root.commitPositions[c2.hash]
            if (!pos2) continue

            var inheritedKey = ""
            if (c2.parentHashes && c2.parentHashes.length) {
                // Find a parent in the same column; if found, inherit its color key.
                for (var pi = 0; pi < c2.parentHashes.length; pi++) {
                    var pHash = c2.parentHashes[pi]
                    var pPos = root.commitPositions[pHash]
                    if (pPos && pPos.column === pos2.column) {
                        inheritedKey = colorKeyByHash[pHash] || ""
                        break
                    }
                }
            }

            if (inheritedKey) {
                c2.colorKey = inheritedKey
            } else {
                // Start a new segment (unique per checkout / new branch instance)
                c2.colorKey = "lane-seg:" + pos2.column + ":" + c2.hash
            }

            colorKeyByHash[c2.hash] = c2.colorKey
        }

        root.commits = commits.slice(0)
    }

    /* Children
     * ****************************************************************************************/
    Rectangle{
        anchors.fill: parent
        color : "#FFFFFF"

        // Empty state (no commits to render)
        Item {
            anchors.fill: parent
            visible: !root.commits || root.commits.length === 0
            z: 999

            Column {
                id: emptyStateColumn
                anchors.centerIn: parent
                spacing: 10

                // Give the column a concrete width so children using width bindings can render.
                width: Math.min(parent.width, 360)

                Text {
                    text: "\uf071"
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: 34
                    color: Style.colors.mutedText
                    horizontalAlignment: Text.AlignHCenter
                    width: emptyStateColumn.width
                }

                Text {
                    text: "no commit to show"
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 14
                    font.weight: 600
                    color: Style.colors.mutedText
                    horizontalAlignment: Text.AlignHCenter
                    width: emptyStateColumn.width
                    wrapMode: Text.WordWrap
                }

                Text {
                    text: root.emptyStateDetailsText()
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 12
                    font.weight: 400
                    color: Style.colors.placeholderText
                    horizontalAlignment: Text.AlignHCenter
                    width: emptyStateColumn.width
                    wrapMode: Text.WordWrap
                }
            }
        }

        ColumnLayout {          
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: header
                Layout.fillWidth: true
                visible: root.commits && root.commits.length > 0
                Layout.preferredHeight: visible ? 30 : 0

                RowLayout {
                    anchors.fill: parent
                    spacing: 0

                    Rectangle {
                        Layout.preferredWidth: root.commitsColGraphWidth
                        Layout.fillHeight: true
                        color: graphHeaderMouseArea.containsMouse ? "#E8E8E8" : "transparent"
                        
                        MouseArea {
                            id: graphHeaderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: graphDividerMouseArea.containsMouse ? "#4A6FA5" : "#f2f2f2"

                            MouseArea {
                                id: graphDividerMouseArea
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 10
                                anchors.rightMargin: -5
                                hoverEnabled: true
                                cursorShape: Qt.SizeHorCursor

                                property real startX: 0
                                property int startWidth: 0

                                onPressed: function(mouse) {
                                    startX = mouseX + mapToItem(header, 0, 0).x
                                    startWidth = root.commitsColGraphWidth
                                }

                                onPositionChanged: function(mouse) {
                                    if (!pressed) return

                                    var currentX = mouseX + mapToItem(header, 0, 0).x
                                    var delta = currentX - startX
                                    
                                    // Calculate new width with minimum constraint
                                    var newWidth = Math.max(root.minColGraphWidth, startWidth + delta)
                                    var actualDelta = newWidth - root.commitsColGraphWidth
                                    
                                    // Adjust next column (BranchTag) inversely
                                    var newBranchTagWidth = root.commitsColBranchTagWidth - actualDelta
                                    
                                    // Ensure next column doesn't go below minimum
                                    if (newBranchTagWidth < root.minColBranchTagWidth) {
                                        newBranchTagWidth = root.minColBranchTagWidth
                                        newWidth = root.commitsColGraphWidth + (root.commitsColBranchTagWidth - root.minColBranchTagWidth)
                                    }
                                    
                                    if (newWidth !== root.commitsColGraphWidth) {
                                        root.commitsColGraphWidth = newWidth
                                        root.commitsColBranchTagWidth = newBranchTagWidth
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.commitsColBranchTagWidth
                        Layout.fillHeight: true
                        color: branchTagHeaderMouseArea.containsMouse ? "#E8E8E8" : "transparent"
                        
                        MouseArea {
                            id: branchTagHeaderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                        }

                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignLeft
                            anchors.leftMargin: 5
                            text: "Branch/Tag"
                            color: "#000000"
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: branchTagDividerMouseArea.containsMouse ? "#4A6FA5" : "#f2f2f2"

                            MouseArea {
                                id: branchTagDividerMouseArea
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 10
                                anchors.rightMargin: -5
                                hoverEnabled: true
                                cursorShape: Qt.SizeHorCursor

                                property real startX: 0
                                property int startWidth: 0

                                onPressed: function(mouse) {
                                    startX = mouseX + mapToItem(header, 0, 0).x
                                    startWidth = root.commitsColBranchTagWidth
                                }

                                onPositionChanged: function(mouse) {
                                    if (!pressed) return

                                    var currentX = mouseX + mapToItem(header, 0, 0).x
                                    var delta = currentX - startX
                                    
                                    // Calculate new width with minimum constraint
                                    var newWidth = Math.max(root.minColBranchTagWidth, startWidth + delta)
                                    var actualDelta = newWidth - root.commitsColBranchTagWidth
                                    
                                    // Adjust next column (Message) inversely
                                    var newMessageWidth = root.commitsColMessageWidth - actualDelta
                                    
                                    // Ensure next column doesn't go below minimum
                                    if (newMessageWidth < root.minColMessageWidth) {
                                        newMessageWidth = root.minColMessageWidth
                                        newWidth = root.commitsColBranchTagWidth + (root.commitsColMessageWidth - root.minColMessageWidth)
                                    }
                                    
                                    if (newWidth !== root.commitsColBranchTagWidth) {
                                        root.commitsColBranchTagWidth = newWidth
                                        root.commitsColMessageWidth = newMessageWidth
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.commitsColMessageWidth
                        Layout.fillHeight: true
                        color: messageHeaderMouseArea.containsMouse ? "#E8E8E8" : "transparent"
                        
                        MouseArea {
                            id: messageHeaderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                        }

                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignLeft
                            anchors.leftMargin: 5
                            text: "Message"
                            color: "#000000"
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: messageDividerMouseArea.containsMouse ? "#4A6FA5" : "#f2f2f2"

                            MouseArea {
                                id: messageDividerMouseArea
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 10
                                anchors.rightMargin: -5
                                hoverEnabled: true
                                cursorShape: Qt.SizeHorCursor

                                property real startX: 0
                                property int startWidth: 0

                                onPressed: function(mouse) {
                                    startX = mouseX + mapToItem(header, 0, 0).x
                                    startWidth = root.commitsColMessageWidth
                                }

                                onPositionChanged: function(mouse) {
                                    if (!pressed) return

                                    var currentX = mouseX + mapToItem(header, 0, 0).x
                                    var delta = currentX - startX
                                    
                                    // Calculate new width with minimum constraint
                                    var newWidth = Math.max(root.minColMessageWidth, startWidth + delta)
                                    var actualDelta = newWidth - root.commitsColMessageWidth
                                    
                                    // Adjust next column (Author) inversely
                                    var newAuthorWidth = root.commitsColAuthorWidth - actualDelta
                                    
                                    // Ensure next column doesn't go below minimum
                                    if (newAuthorWidth < root.minColAuthorWidth) {
                                        newAuthorWidth = root.minColAuthorWidth
                                        newWidth = root.commitsColMessageWidth + (root.commitsColAuthorWidth - root.minColAuthorWidth)
                                    }
                                    
                                    if (newWidth !== root.commitsColMessageWidth) {
                                        root.commitsColMessageWidth = newWidth
                                        root.commitsColAuthorWidth = newAuthorWidth
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.commitsColAuthorWidth
                        Layout.fillHeight: true
                        color: authorHeaderMouseArea.containsMouse ? "#E8E8E8" : "transparent"
                        
                        MouseArea {
                            id: authorHeaderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                        }

                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignLeft
                            anchors.leftMargin: 5
                            text: "Author"
                            color: "#000000"
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }

                        Rectangle {
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            width: 1
                            color: authorDividerMouseArea.containsMouse ? "#4A6FA5" : "#f2f2f2"

                            MouseArea {
                                id: authorDividerMouseArea
                                anchors.right: parent.right
                                anchors.top: parent.top
                                anchors.bottom: parent.bottom
                                width: 10
                                anchors.rightMargin: -5
                                hoverEnabled: true
                                cursorShape: Qt.SizeHorCursor

                                property real startX: 0
                                property int startWidth: 0

                                onPressed: function(mouse) {
                                    startX = mouseX + mapToItem(header, 0, 0).x
                                    startWidth = root.commitsColAuthorWidth
                                }

                                onPositionChanged: function(mouse) {
                                    if (!pressed) return

                                    var currentX = mouseX + mapToItem(header, 0, 0).x
                                    var delta = currentX - startX
                                    
                                    // Calculate new width with minimum constraint
                                    var newWidth = Math.max(root.minColAuthorWidth, startWidth + delta)
                                    var actualDelta = newWidth - root.commitsColAuthorWidth
                                    
                                    // Adjust next column (Date) inversely
                                    var newDateWidth = root.commitsColDateWidth - actualDelta
                                    
                                    // Ensure next column doesn't go below minimum
                                    if (newDateWidth < root.minColDateWidth) {
                                        newDateWidth = root.minColDateWidth
                                        newWidth = root.commitsColAuthorWidth + (root.commitsColDateWidth - root.minColDateWidth)
                                    }
                                    
                                    if (newWidth !== root.commitsColAuthorWidth) {
                                        root.commitsColAuthorWidth = newWidth
                                        root.commitsColDateWidth = newDateWidth
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: root.commitsColDateWidth
                        Layout.fillHeight: true
                        Layout.alignment: Qt.AlignRight
                        color: dateHeaderMouseArea.containsMouse ? "#E8E8E8" : "transparent"
                        
                        MouseArea {
                            id: dateHeaderMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            propagateComposedEvents: true
                            onPressed: function(mouse) { mouse.accepted = false }
                            onReleased: function(mouse) { mouse.accepted = false }
                        }

                        Label {
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            horizontalAlignment: Text.AlignLeft
                            anchors.leftMargin: 5
                            text: "Date"
                            color: "#000000"
                            font.pixelSize: 11
                            font.bold: true
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            RowLayout {
                id: mainRowLayout
                spacing: 0

                Rectangle {
                    id: graphColumnRect
                    Layout.fillWidth: false
                    Layout.preferredWidth: root.commitsColGraphWidth + root.commitsColBranchTagWidth
                    Layout.fillHeight: true

                    Flickable {
                        id: graphFlickable
                        anchors.fill: parent
                        clip: true
                        // Calculate contentWidth based on max columns to avoid binding loop
                        contentWidth: {
                            if (root.commits.length === 0) return width
                            var maxCols = 0
                            for (var i = 0; i < root.commits.length; i++) {
                                var commit = root.commits[i]
                                var pos = root.commitPositions[commit.hash]
                                if (pos && pos.column > maxCols) {
                                    maxCols = pos.column
                                }
                            }
                            var minWidth = 40 + (maxCols + 1) * root.columnSpacing + 300
                            return Math.max(width, minWidth)
                        }
                        contentHeight: Math.max(height, root.commits.length * (root.commitItemHeight + (commitItemSpacing * 2)))
                        boundsBehavior: Flickable.StopAtBounds

                        property bool syncScroll: false

                        // Sync scroll position with commits list
                        onContentYChanged: {
                            // Infinite scroll trigger (graph side)
                            if (!root.isLoadingMore && root.hasMoreCommits) {
                                var remaining = graphFlickable.contentHeight - (graphFlickable.contentY + graphFlickable.height)
                                if (remaining < 300) {
                                    root.loadMoreCommits()
                                }
                            }

                            if (!syncScroll && graphFlickable.contentHeight > graphFlickable.height) {
                                syncScroll = true
                                var graphMaxY = graphFlickable.contentHeight - graphFlickable.height
                                if (graphMaxY > 0) {
                                    var ratio = graphFlickable.contentY / graphMaxY
                                    var listMaxY = commitsListView.contentHeight - commitsListView.height
                                    if (listMaxY > 0) {
                                        commitsListView.syncScroll = true
                                        commitsListView.contentY = ratio * listMaxY
                                        commitsListView.syncScroll = false
                                    }
                                }
                                syncScroll = false
                            }
                        }

                        // Single Canvas for entire DAG
                        Canvas {
                            id: graphCanvas
                            // Use Flickable's contentWidth
                            width: graphFlickable.contentWidth
                            height: root.commits.length * (root.commitItemHeight + (root.commitItemSpacing * 2))

                            Connections {
                                target: root
                                function onSelectedCommitChanged() {
                                    graphCanvas.requestPaint()
                                }
                            }

                            Component.onCompleted: {
                                graphCanvas.requestPaint()
                            }

                            Connections {
                                target: root
                                function onCommitsChanged() {
                                    var newHeight = Math.max(graphFlickable.height, root.commits.length * (root.commitItemHeight + (commitItemSpacing * 2)))
                                    graphCanvas.height = newHeight
                                    graphFlickable.contentHeight = newHeight
                                    graphCanvas.requestPaint()
                                    // Force contentWidth recalculation
                                    graphFlickable.contentWidth = Qt.binding(function() {
                                        if (root.commits.length === 0) return graphFlickable.width
                                        var maxCols = 0
                                        for (var i = 0; i < root.commits.length; i++) {
                                            var commit = root.commits[i]
                                            var pos = root.commitPositions[commit.hash]
                                            if (pos && pos.column > maxCols) {
                                                maxCols = pos.column
                                            }
                                        }
                                        var minWidth = 40 + (maxCols + 1) * root.columnSpacing + 300
                                        return Math.max(graphFlickable.width, minWidth)
                                    })
                                }
                            }

                            Connections {
                                target: root
                                function onCommitsColGraphWidthChanged() {
                                    graphCanvas.requestPaint()
                                }
                            }

                            property var svgImage: Image {
                                source: "qrc:/GitEase/Resources/Images/defaultUserIcon.svg"
                                anchors.centerIn: parent
                                height: 14.5
                                width: 14.5
                            }

                            onPaint: {
                                // Always clear the canvas first. Otherwise, when commits becomes empty
                                // (e.g., filter has no results), the old graph remains visible.
                                var ctx = getContext("2d");

                                // Erase previous frame completely
                                ctx.clearRect(0, 0, width, height);
                                ctx.globalAlpha = 1.0;
                                ctx.fillStyle = "#FFFFFF";
                                ctx.fillRect(0, 0, width, height);
                                
                                let showAvatar = root.appModel?.appSettings?.generalSettings?.showAvatar ?? true

                                if (!root.commits || root.commits.length === 0)
                                    return;

                                // Calculate center offset for graph
                                var maxColumns = 0;
                                for (var i = 0; i < root.commits.length; i++) {
                                    var commit = root.commits[i];
                                    var pos = root.commitPositions[commit.hash];
                                    if (pos && pos.column > maxColumns) {
                                        maxColumns = pos.column;
                                    }
                                }

                                // Start graph from left side
                                var centerOffset = root.columnSpacing / 2; // Padding from left edge

                                // Build quick lookup: hash -> commit object (for edge coloring)
                                var commitByHash = {}
                                for (var bi0 = 0; bi0 < root.commits.length; bi0++) {
                                    var c0m = root.commits[bi0]
                                    if (c0m && c0m.hash)
                                        commitByHash[c0m.hash] = c0m
                                }

                                // Track branch HEAD commits for labels.
                                // No separate branches model: HEAD labels are stored on commits as commit.branchNames.
                                // Build a map: branchName -> commitHash for quick checks.
                                var branchLatestCommit = {};
                                for (var bi = 0; bi < root.commits.length; bi++) {
                                    var bc = root.commits[bi];
                                    if (bc && bc.branchNames && bc.branchNames.length) {
                                        for (var bni = 0; bni < bc.branchNames.length; bni++) {
                                            var bn = bc.branchNames[bni];
                                            if (bn)
                                                branchLatestCommit[bn] = bc.hash;
                                        }
                                    }
                                }
                                
                                // Build edge routing information for better visualization
                                // Track ALL parent connections
                                var parentInSameLane = {};
                                var crossLaneEdges = [];  // Store cross-lane edges (different columns)
                                
                                for (var j = 0; j < root.commits.length; j++) {
                                    var c0 = root.commits[j];
                                    var pos0 = root.commitPositions[c0.hash];
                                    if (!pos0 || !c0.parentHashes) continue;
                                    
                                    // Process ALL parents
                                    for (var p = 0; p < c0.parentHashes.length; p++) {
                                        var parentHash = c0.parentHashes[p];
                                        var parentPos = root.commitPositions[parentHash];
                                        if (!parentPos) continue;
                                        
                                        if (parentPos.column === pos0.column) {
                                            // Same lane - only store first one for straight line
                                            if (!parentInSameLane[c0.hash]) {
                                                parentInSameLane[c0.hash] = parentHash;
                                            }
                                        } else {
                                            // Different lane - draw cross-lane edge
                                            // For merge commits: draw FROM parent TO merge commit
                                            // For normal commits: draw FROM child TO parent
                                            var isMerge = c0.commitType === "merge";
                                            crossLaneEdges.push({
                                                from: isMerge ? parentHash : c0.hash,
                                                to: isMerge ? c0.hash : parentHash,
                                                fromPos: isMerge ? parentPos : pos0,
                                                toPos: isMerge ? pos0 : parentPos,
                                                isMerge: isMerge
                                            });
                                        }
                                    }
                                }

                                // PHASE 1: Draw all continuation lines (same-lane parent connections)
                                for (var j = 0; j < root.commits.length; j++) {
                                    var commit2 = root.commits[j];
                                    var pos2 = root.commitPositions[commit2.hash];
                                    if (!pos2) continue;

                                    var centerX = centerOffset + pos2.column * root.columnSpacing + root.columnSpacing / 2;
                                    var centerY = pos2.y + root.commitItemHeight / 2 + root.commitItemSpacing;

                                    // Draw straight line to parent in same lane
                                    var parentHash = parentInSameLane[commit2.hash];
                                    if (parentHash) {
                                        var parentPos = root.commitPositions[parentHash];
                                        if (parentPos) {
                                            var parentX = centerOffset + parentPos.column * root.columnSpacing + root.columnSpacing / 2;
                                            var parentY = parentPos.y + root.commitItemHeight / 2 + root.commitItemSpacing;
                                            
                                            var branchColor2 = commitColor(commit2);

                                            ctx.save();
                                            ctx.strokeStyle = branchColor2;
                                            ctx.globalAlpha = 0.9;
                                            ctx.lineWidth = 2.5;

                                            ctx.beginPath();
                                            ctx.moveTo(centerX, centerY);
                                            ctx.lineTo(parentX, parentY);
                                            ctx.stroke();
                                            ctx.restore();
                                        }
                                    }
                                }
                                
                                // PHASE 2: Draw cross-lane edges (Diagonal/Bezier curves for different columns)
                                for (var edgeIdx = 0; edgeIdx < crossLaneEdges.length; edgeIdx++) {
                                    var edge = crossLaneEdges[edgeIdx];
                                    var fromPos = edge.fromPos;
                                    var toPos = edge.toPos;
                                    
                                    var fromX = centerOffset + fromPos.column * root.columnSpacing + root.columnSpacing / 2;
                                    var fromY = fromPos.y + root.commitItemHeight / 2 + root.commitItemSpacing;
                                    var toX = centerOffset + toPos.column * root.columnSpacing + root.columnSpacing / 2;
                                    var toY = toPos.y + root.commitItemHeight / 2 + root.commitItemSpacing;
                                    
                                    // Color edge by the originating commit's lane/graph color
                                    var edgeColorVal = edgeColor(edge, commitByHash)
                                    
                                    ctx.save();
                                    ctx.strokeStyle = edgeColorVal;
                                    ctx.globalAlpha = 0.85;
                                    ctx.lineWidth = 2.5;
                                    
                                    ctx.beginPath();
                                    
                                    // Draw smooth Bezier curve for diagonal connection
                                    ctx.moveTo(fromX, fromY);
                                    
                                    // Calculate control points for smooth curve
                                    var verticalDistance = Math.abs(toY - fromY);
                                    var horizontalDistance = Math.abs(toX - fromX);
                                    
                                    // Use bezier curve for smooth diagonal lines
                                    // Control points are offset to create a natural curve
                                    var controlOffset = Math.min(verticalDistance * 0.6, 40);
                                    
                                    let isUpside = toY < fromY

                                    if (isUpside) {
                                        ctx.bezierCurveTo(fromX, toY + 5, fromX - 2, toY, fromX - 20, toY);
                                        ctx.lineTo(toX, toY);
                                    } else {
                                        ctx.lineTo(fromX, toY - 20);
                                        ctx.bezierCurveTo(fromX, toY - 20, fromX - 2, toY, fromX - 20, toY);
                                        ctx.lineTo(toX, toY);
                                    }
                                    
                                    ctx.stroke();
                                    ctx.restore();
                                }

                                // First pass: Draw lines from nodes to branch/tag labels (only for HEAD commits)
                                for (var lineIdx = 0; lineIdx < root.commits.length; lineIdx++) {
                                    var commitForLine = root.commits[lineIdx];
                                    var posForLine = root.commitPositions[commitForLine.hash];
                                    if (!posForLine) continue;

                                    // Check if this commit is a HEAD of ANY branch
                                    var isHeadCommitForLabels = false;
                                    var headBranchesForThisCommit = [];
                                    
                                    // Check ALL branches to see if this commit is a HEAD
                                    for (var branchKey in branchLatestCommit) {
                                        if (branchLatestCommit[branchKey] === commitForLine.hash) {
                                            isHeadCommitForLabels = true;
                                            headBranchesForThisCommit.push(branchKey);
                                        }
                                    }

                                    // Only show labels for HEAD commits
                                    if (!isHeadCommitForLabels) continue;

                                    var centerXForLine = centerOffset + posForLine.column * root.columnSpacing + root.columnSpacing / 2;
                                    var centerYForLine = posForLine.y + root.commitItemHeight / 2 + root.commitItemSpacing;

                                    // Collect all labels (tags first, then branches) for this commit
                                    // Label colors are based on the commit's lane/graph color
                                    var laneLabelColor = commitColor(commitForLine)
                                    var allLabels = [];

                                    // Add tag labels first (left side)
                                    if (commitForLine.tagNames && commitForLine.tagNames.length > 0) {
                                        for (var tIdx = 0; tIdx < commitForLine.tagNames.length; tIdx++) {
                                            var tagName = commitForLine.tagNames[tIdx];
                                            allLabels.push({
                                                text: tagName,
                                                color: laneLabelColor
                                            });
                                        }
                                    }

                                    // Add branch labels for HEAD branches
                                    // Each label uses the lane/graph color
                                    for (var hbi = 0; hbi < headBranchesForThisCommit.length; hbi++) {
                                        var headBranchName = headBranchesForThisCommit[hbi];
                                        allLabels.push({
                                            text: headBranchName + " (HEAD)",
                                            color: laneLabelColor
                                        });
                                    }

                                    // Draw all labels on same horizontal line
                                    if (allLabels.length > 0) {
                                        // Align labels to start at the Graph/BranchTag divider position
                                        // But ensure labels start AFTER the commit node (never overlap or go backwards)
                                        var dividerPosition = root.commitsColGraphWidth + 10;  // Position at divider + small padding
                                        var nodeEndPosition = centerXForLine + 20;  // Node position + node radius + padding
                                        var labelStartX = Math.max(dividerPosition, nodeEndPosition);  // Use whichever is further right
                                        var labelY = centerYForLine;  // Same Y as node (horizontal line)
                                        var currentLabelX = labelStartX;
                                        var labelSpacing = 8;  // Horizontal spacing between labels

                                        // Calculate positions for all labels
                                        var labelPositions = [];
                                        for (var calcIdx = 0; calcIdx < allLabels.length; calcIdx++) {
                                            var calcLabelInfo = allLabels[calcIdx];
                                            ctx.font = "bold 11px Arial";
                                            ctx.textAlign = "left";
                                            var calcTextMetrics = ctx.measureText(calcLabelInfo.text);
                                            var calcLabelWidth = calcTextMetrics.width + 16;
                                            labelPositions.push({
                                                x: currentLabelX,
                                                width: calcLabelWidth,
                                                info: calcLabelInfo
                                            });
                                            currentLabelX += calcLabelWidth + labelSpacing;
                                        }

                                        // Draw single connecting line using first label's color
                                        if (labelPositions.length > 0) {
                                            var firstLabel = labelPositions[0];
                                            var lastLabel = labelPositions[labelPositions.length - 1];
                                            var lineEndX = lastLabel.x + lastLabel.width;
                                            
                                            ctx.save();
                                            ctx.strokeStyle = laneLabelColor;  // Use commit lane/graph color
                                            ctx.globalAlpha = 0.8;
                                            ctx.lineWidth = 5;

                                            ctx.beginPath();
                                            ctx.moveTo(centerXForLine, centerYForLine);
                                            ctx.lineTo(lineEndX, labelY);
                                            ctx.stroke();
                                            ctx.restore();
                                        }

                                        // Draw all labels
                                        for (var labelDrawIdx = 0; labelDrawIdx < labelPositions.length; labelDrawIdx++) {
                                            var labelPos = labelPositions[labelDrawIdx];
                                            var labelInfo = labelPos.info;
                                            var labelX = labelPos.x;
                                            var labelWidth = labelPos.width;
                                            var labelHeight = 20;
                                            var labelRectY = labelY - labelHeight / 2;

                                            ctx.save();
                                            ctx.fillStyle = labelInfo.color;
                                            ctx.globalAlpha = 0.95;
                                            GraphUtils.drawRoundedRect(ctx, labelX, labelRectY, labelWidth, labelHeight, 2);
                                            ctx.fill();

                                            // Enhanced label styling with better contrast
                                            var contrastColor = GraphUtils.getContrastColor(labelInfo.color);
                                            ctx.fillStyle = contrastColor;
                                            ctx.globalAlpha = 1.0;
                                            ctx.font = "bold 11px 'Segoe UI', Arial, sans-serif";
                                            ctx.textAlign = "left";
                                            ctx.textBaseline = "middle";
                                            ctx.fillText(labelInfo.text, labelX + 8, labelY);
                                            ctx.restore();
                                        }
                                    }
                                }

                                // Second pass: Draw commit nodes (on top of lines)
                                for (var k = 0; k < root.commits.length; k++) {
                                    var commit3 = root.commits[k];
                                    var pos3 = root.commitPositions[commit3.hash];
                                    if (!pos3) continue;

                                    var centerX2 = centerOffset + pos3.column * root.columnSpacing + root.columnSpacing / 2;
                                    var centerY2 = pos3.y + root.commitItemHeight / 2 + root.commitItemSpacing;

                                    var branchColor3 = commitColor(commit3);

                                    // Determine HEAD status without falling back to "main"
                                    var isHeadCommit = false;
                                    if (commit3.branchNames && commit3.branchNames.length) {
                                        for (var hb = 0; hb < commit3.branchNames.length; hb++) {
                                            var bname = commit3.branchNames[hb]
                                            if (branchLatestCommit && branchLatestCommit[bname] === commit3.hash) {
                                                isHeadCommit = true;
                                                break;
                                            }
                                        }
                                    }
                                    var isSelected = root.selectedCommit && root.selectedCommit.hash === commit3.hash;

                                    // Highlight selected commit row
                                    if (isSelected) {
                                        ctx.fillStyle = "#6088B2DF";
                                        ctx.fillRect(0, pos3.y, graphCanvas.width, root.commitItemHeight + (root.commitItemSpacing * 2));
                                    }

                                    var avatarSize = showAvatar ? root.commitItemHeight : 10;
                                    var avatarRadius = avatarSize / 2;

                                    // All commits: Circle with avatar (same style)
                                    ctx.save();
                                    ctx.strokeStyle = isSelected ? GraphUtils.darkenColor(branchColor3, 0.2): GraphUtils.lightenColor(branchColor3, 0.3);
                                    ctx.lineWidth = isSelected ? 4 : 2.5;

                                    ctx.beginPath();
                                    ctx.arc(centerX2, centerY2, avatarRadius, 0, 2 * Math.PI);
                                    ctx.fillStyle = showAvatar ? "#D9D9D9" : GraphUtils.lightenColor(branchColor3, 0.3);
                                    ctx.fill();
                                    ctx.stroke();

                                    if (showAvatar) {
                                        // Draw avatar icon
                                        ctx.fillStyle = "#ffffff";
                                        ctx.font = (avatarSize * 0.8) + "px Arial";
                                        ctx.textAlign = "center";
                                        ctx.textBaseline = "middle";

                                        var drawX = centerX2 - svgImage.width / 2;
                                        var drawY = centerY2 - svgImage.height / 2;
                                        ctx.drawImage(svgImage, drawX, drawY);
                                    }
                                    ctx.restore();
                                }

                            }
                        }
                    }
                }

                // Commits ListView
                ListView {
                    id: commitsListView
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.commitsColMessageWidth + root.commitsColAuthorWidth+ root.commitsColDateWidth
                    Layout.fillHeight: true
                    model: root.commits
                    clip: true

                    property bool syncScroll: false

                    // Sync scroll position with graph
                    onContentYChanged: {
                        // Infinite scroll trigger (list side)
                        if (!root.isLoadingMore && root.hasMoreCommits) {
                            var remaining = commitsListView.contentHeight - (commitsListView.contentY + commitsListView.height)
                            if (remaining < 300) {
                                root.loadMoreCommits()
                            }
                        }

                        if (!syncScroll && commitsListView.contentHeight > commitsListView.height) {
                            syncScroll = true
                            var listMaxY = commitsListView.contentHeight - commitsListView.height
                            if (listMaxY > 0) {
                                var ratio = commitsListView.contentY / listMaxY
                                var graphMaxY = graphFlickable.contentHeight - graphFlickable.height
                                if (graphMaxY > 0) {
                                    graphFlickable.syncScroll = true
                                    graphFlickable.contentY = ratio * graphMaxY
                                    graphFlickable.syncScroll = false
                                }
                            }
                            syncScroll = false
                        }
                    }

                    delegate: Rectangle {
                        width: ListView.view.width
                        height: root.commitItemHeight + commitItemSpacing + commitItemSpacing

                        property var commitData: modelData
                        property bool isHovered: false
                        property bool isSelected: root.selectedCommit && root.selectedCommit.hash === commitData.hash

                        color: {
                            if (isSelected) {
                                return "#6088B2DF";
                            } else if (isHovered) {
                                return "#EFEFEF";
                            } else {
                                return "#FFFFFF";
                            }
                        }

                        radius: (isSelected || isHovered) ? 4 : 0


                        RowLayout {
                            anchors.fill: parent
                            spacing: 0
                            anchors.topMargin: commitItemSpacing
                            anchors.bottomMargin: commitItemSpacing

                            // Column 1: Commit Message
                            ColumnLayout {
                                Layout.fillWidth: false
                                Layout.preferredWidth: root.commitsColMessageWidth
                                Layout.fillHeight: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true

                                    Rectangle {
                                        Layout.preferredWidth: 1
                                        Layout.fillHeight: true
                                        width: 1
                                        color: "#f2f2f2"
                                    }

                                    // Branch color indicator bar
                                    Rectangle {
                                        id: branchColorIndicator
                                        Layout.preferredWidth: 3
                                        Layout.preferredHeight: commitItemHeight * 0.8
                                        Layout.alignment: Qt.AlignVCenter
                                        radius: 6

                                        // Color indicator by graph lane/column (same color as the drawn graph line)
                                        color: {
                                            return commitColor(commitData)
                                        }
                                    }

                                    Label {
                                        text: commitData.summary || ""
                                        color: "#000000"
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 10
                                        font.family: Style.fontTypes.roboto
                                        font.weight: 400
                                        font.letterSpacing: 0.2
                                        Layout.fillWidth: true
                                        Layout.leftMargin: 6
                                        elide: Text.ElideRight
                                    }
                                }
                            }

                            // Column 2: Author
                            ColumnLayout {
                                Layout.preferredWidth: root.commitsColAuthorWidth
                                Layout.fillHeight: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true

                                    Rectangle {
                                        Layout.preferredWidth: 1
                                        Layout.fillHeight: true
                                        width: 1
                                        color: "#f2f2f2"
                                    }

                                    Label {
                                        text: commitData.author || ""
                                        color: "#000000"
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 12
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignLeft
                                        elide: Text.ElideRight
                                        wrapMode: Text.NoWrap
                                    }
                                }
                            }

                            // Column 3: Date and Time (in one line)
                            ColumnLayout {
                                Layout.preferredWidth: root.commitsColDateWidth
                                Layout.fillHeight: true
                                spacing: 0

                                RowLayout {
                                    Layout.fillWidth: true

                                    Rectangle {
                                        Layout.preferredWidth: 1
                                        Layout.fillHeight: true
                                        width: 1
                                        color: "#f2f2f2"
                                    }

                                    Label {
                                        text: GraphUtils.formatDate(commitData.authorDate) + " " + GraphUtils.formatTime(commitData.authorDate)
                                        color: "#000000"
                                        verticalAlignment: Text.AlignVCenter
                                        font.pixelSize: 10
                                        Layout.fillWidth: true
                                        horizontalAlignment: Text.AlignLeft
                                        wrapMode: Text.NoWrap
                                    }
                                }
                            }
                        }

                        MouseArea {
                            id: commitMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.selectedCommit = commitData
                                root.commitClicked(commitData.hash)
                            }
                            onEntered: {
                                isHovered = true
                            }
                            onExited: {
                                isHovered = false
                            }
                        }
                    }
                }
            }
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

            var parentHashes = []
            var details = commit
            if (details && details.parentHashes) {
                parentHashes = details.parentHashes
            }

            var obj = {
                hash: commit.hash,
                shortHash: commit.shortHash,
                message: commit.message,
                summary: commit.summary,
                author: commit.author,
                authorEmail: commit.authorEmail,
                authorDate: commit.authorDate,

                parentHashes: parentHashes,
                commitType: (parentHashes.length > 1) ? "merge" : "normal",

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

        commitsListView.positionViewAtIndex(i, ListView.Contain)
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
        if (!repositoryController || !root.appModel || !root.appModel.currentRepository) {
            return;
        }

        GraphUtils.clearBranchColorCache();
        GraphUtils.clearTagColorCache();
        GraphUtils.clearCategoryColorCache();

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

    Connections {
        target: repositoryController
        function onRepositorySelected(repo) {
            reloadAll();
        }
    }

    Connections {
        target: appModel?.appSettings?.generalSettings ?? null
        function onShowAvatarChanged() {
            graphCanvas.requestPaint()
        }
    }
}
