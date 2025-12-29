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
    property RepositoryController repositoryController: null

    /* Property Declarations
     * ****************************************************************************************/
    property var commits: []
    property var selectedCommit: null

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


    /**
     * Load commit data and calculate graph layout positions
     */
    function loadData() {
        commitPositions = GraphLayout.calculateDAGPositions(
            root.commits,
            root.columnSpacing,
            root.commitItemHeight,
            root.commitItemSpacing
        );
    }

    /* Children
     * ****************************************************************************************/
    Rectangle{
        anchors.fill: parent
        color : "#FFFFFF"

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                id: header
                Layout.fillWidth: true
                Layout.preferredHeight: 30

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

                                if (!root.commits || root.commits.length === 0)
                                    return;

                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);
                                ctx.globalAlpha = 1.0;

                                if (root.commits.length === 0) return;

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
                                            
                                            // Get color from commit's branch (prefer non-main)
                                            var branchColor2 = null;
                                            if (commit2.branchNames && commit2.branchNames.length > 0) {
                                                for (var bi = 0; bi < commit2.branchNames.length; bi++) {
                                                    var bn = commit2.branchNames[bi];
                                                    if (bn !== "main" && bn !== "origin/main" && bn !== "master") {
                                                        branchColor2 = GraphUtils.getBranchColor(bn);
                                                        break;
                                                    }
                                                }
                                                // If only main branches found, use first branch
                                                if (!branchColor2) {
                                                    branchColor2 = GraphUtils.getBranchColor(commit2.branchNames[0]);
                                                }
                                            }
                                            
                                            // Fallback if no branches
                                            if (!branchColor2) {
                                                branchColor2 = GraphUtils.generateRandomColor();
                                            }

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
                                    
                                    // Find the commit at fromPos and get its branch color
                                    var edgeColor = null;
                                    for (var ci = 0; ci < root.commits.length; ci++) {
                                        var c = root.commits[ci];
                                        var cPos = root.commitPositions[c.hash];
                                        if (cPos && cPos.column === fromPos.column && cPos.y === fromPos.y) {
                                            if (c.branchNames && c.branchNames.length > 0) {
                                                // Prefer non-main branches
                                                for (var bi = 0; bi < c.branchNames.length; bi++) {
                                                    var bn = c.branchNames[bi];
                                                    if (bn !== "main" && bn !== "origin/main" && bn !== "master") {
                                                        edgeColor = GraphUtils.getBranchColor(bn);
                                                        break;
                                                    }
                                                }
                                                // If only main branches found, use first branch
                                                if (!edgeColor) {
                                                    edgeColor = GraphUtils.getBranchColor(c.branchNames[0]);
                                                }
                                            }
                                            break;
                                        }
                                    }
                                    
                                    // Fallback if commit not found
                                    if (!edgeColor) {
                                        edgeColor = GraphUtils.generateRandomColor();
                                    }
                                    
                                    ctx.save();
                                    ctx.strokeStyle = edgeColor;
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
                                    
                                    var cp1X = fromX;
                                    var cp1Y = fromY + (toY > fromY ? controlOffset : -controlOffset);
                                    var cp2X = toX;
                                    var cp2Y = toY - (toY > fromY ? controlOffset : -controlOffset);
                                    
                                    ctx.bezierCurveTo(cp1X, cp1Y, cp2X, cp2Y, toX, toY);
                                    
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
                                    var allLabels = [];

                                    // Add tag labels first (left side)
                                    if (commitForLine.tagNames && commitForLine.tagNames.length > 0) {
                                        for (var tIdx = 0; tIdx < commitForLine.tagNames.length; tIdx++) {
                                            var tagName = commitForLine.tagNames[tIdx];
                                            var tagColor = GraphUtils.getTagColor(tagName);
                                            allLabels.push({
                                                text: tagName,
                                                color: tagColor
                                            });
                                        }
                                    }

                                    // Add branch labels for HEAD branches
                                    // Each label shows its own branch color
                                    for (var hbi = 0; hbi < headBranchesForThisCommit.length; hbi++) {
                                        var headBranchName = headBranchesForThisCommit[hbi];
                                        var branchColor4 = GraphUtils.getBranchColor(headBranchName);
                                        allLabels.push({
                                            text: headBranchName + " (HEAD)",
                                            color: branchColor4
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
                                            ctx.strokeStyle = firstLabel.info.color;  // Use FIRST label's branch color
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

                                    // Get color from commit's branch (prefer non-main)
                                    var branchColor3 = null;
                                    if (commit3.branchNames && commit3.branchNames.length > 0) {
                                        for (var bi = 0; bi < commit3.branchNames.length; bi++) {
                                            var bn = commit3.branchNames[bi];
                                            if (bn !== "main" && bn !== "origin/main" && bn !== "master") {
                                                branchColor3 = GraphUtils.getBranchColor(bn);
                                                break;
                                            }
                                        }
                                        // If only main branches found, use first branch
                                        if (!branchColor3) {
                                            branchColor3 = GraphUtils.getBranchColor(commit3.branchNames[0]);
                                        }
                                    }
                                    
                                    // Fallback if no branches
                                    if (!branchColor3) {
                                        branchColor3 = GraphUtils.generateRandomColor();
                                    }

                                    var laneBranchName = pos3.branchName || (commit3.branchNames && commit3.branchNames.length > 0 ? commit3.branchNames[0] : "main");
                                    var isHeadCommit = branchLatestCommit && branchLatestCommit[laneBranchName] === commit3.hash;
                                    var isSelected = root.selectedCommit && root.selectedCommit.hash === commit3.hash;

                                    // Highlight selected commit row
                                    if (isSelected) {
                                        ctx.fillStyle = "#6088B2DF";
                                        ctx.fillRect(0, pos3.y, graphCanvas.width, root.commitItemHeight + (root.commitItemSpacing * 2));
                                    }

                                    var avatarSize = root.commitItemHeight;
                                    var avatarRadius = avatarSize / 2;

                                    // All commits: Circle with avatar (same style)
                                    ctx.save();
                                    ctx.strokeStyle = isSelected ? "#aad711" : GraphUtils.lightenColor(branchColor3, 0.6);
                                    ctx.lineWidth = isSelected ? 4 : 2.5;

                                    ctx.beginPath();
                                    ctx.arc(centerX2, centerY2, avatarRadius, 0, 2 * Math.PI);
                                    ctx.fillStyle = "#D9D9D9";
                                    ctx.fill();
                                    ctx.stroke();

                                    // Draw avatar icon
                                    ctx.fillStyle = "#ffffff";
                                    ctx.font = (avatarSize * 0.8) + "px Arial";
                                    ctx.textAlign = "center";
                                    ctx.textBaseline = "middle";

                                    var drawX = centerX2 - svgImage.width / 2;
                                    var drawY = centerY2 - svgImage.height / 2;
                                    ctx.drawImage(svgImage, drawX, drawY);
                                    
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
                                        
                                        color: {
                                            // Get color from the branch this commit belongs to
                                            if (commitData.branchNames && commitData.branchNames.length > 0) {
                                                // Prefer non-main branch names for color
                                                for (var i = 0; i < commitData.branchNames.length; i++) {
                                                    var branchName = commitData.branchNames[i];
                                                    if (branchName !== "main" && branchName !== "origin/main" && branchName !== "master") {
                                                        return GraphUtils.getBranchColor(branchName);
                                                    }
                                                }
                                                // If only main branch, use it
                                                return GraphUtils.getBranchColor(commitData.branchNames[0]);
                                            }
                                            
                                            // Fallback to random color
                                            return GraphUtils.generateRandomColor();
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

        // Build a fast lookup from tip commit hash -> [branchName,...]
        var tipHashToBranches = {}
        if (rawBranches && rawBranches.length) {
            for (var i = 0; i < rawBranches.length; i++) {
                var b = rawBranches[i]
                if (!b || !b.targetHash) continue
                if (!tipHashToBranches[b.targetHash]) tipHashToBranches[b.targetHash] = []
                tipHashToBranches[b.targetHash].push(b.name)
            }
        }

        var compiled = []

        for (var c = 0; c < rawCommits.length; c++) {
            var commit = rawCommits[c]

            // parent hashes come from getCommit()
            var parentHashes = []
            var details = repositoryController.getCommitDetail(commit.hash)
            if (details && details.parentHashes) {
                parentHashes = details.parentHashes
            }

            var branchNames = tipHashToBranches[commit.hash] || []

            compiled.push({
                // base info from getCommits
                hash: commit.hash,
                shortHash: commit.shortHash,
                message: commit.message,
                summary: commit.summary,
                author: commit.author,
                authorEmail: commit.authorEmail,
                authorDate: commit.authorDate,

                // graph-required
                parentHashes: parentHashes,
                commitType: (parentHashes.length > 1) ? "merge" : "normal",
                branchNames: branchNames,
                tagNames: [] // TODO : can't find function in gitWrapperCPP
            })
        }

        return compiled
    }

    function reloadAll() {
        if (!repositoryController || !repositoryController.appModel || !repositoryController.appModel.currentRepository) {
            return;
        }

        GraphUtils.clearBranchColorCache();
        GraphUtils.clearTagColorCache();

        var allBranches = repositoryController.getBranches(repositoryController.appModel.currentRepository);
        var commits = repositoryController.getCommits(repositoryController.appModel.currentRepository);

        root.commits = compileGraphCommits(commits, allBranches);
        loadData();
    }

    Connections {
        target: repositoryController
        function onRepositorySelected(repo) {
            reloadAll();
        }
    }

    Component.onCompleted: {
        reloadAll();
    }
}
