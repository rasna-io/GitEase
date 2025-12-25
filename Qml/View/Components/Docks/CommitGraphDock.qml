import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

import "qrc:/GitEase/Qml/Core/Scripts/GraphLayout.js" as GraphLayout
import "qrc:/GitEase/Qml/Core/Scripts/GraphUtils.js" as GraphUtils


/*! ***********************************************************************************************
 *
 * ************************************************************************************************/
Item {

    id : root

    property var commits: ListModel {}
    property var commitDataArray: []  // Store full commit data with arrays (ListModel loses arrays)
    property var branches: ListModel {}
    property var tags: ListModel {}
    property var selectedCommit: null
    property int graphColumnWidth: 0  // Will be calculated as half of dock width
    property int commitItemHeight: 24  // Reduced spacing between commits
    property int itemsSpacing: 4
    property int columnSpacing: 30  // Increased spacing between branch columns
    property var commitPositions: ({})  // Cache for commit positions {hash: {x, y, column}}

    // Property to receive list of CommitData objects
    property var commitDataList: []
    property int commitsColGraphWidth: parent.width * 0.08
    property int commitsColBranchTagWidth: parent.width * 0.17
    property int commitsColMessageWidth: parent.width * 0.6
    property int commitsColAuthorWidth: parent.width * 0.08
    property int commitsColDateWidth: parent.width * 0.17

    // Dummy data provider - will be loaded in Component.onCompleted
    signal commitClicked(string commitId)

    CommitGraphSimulator {
        id: simulator
        enabled: true
        commitDataArray: root.commitDataArray
        branches: root.branches
        commitDataList: root.commitDataList
        onNewCommitsReady: function(newCommitList) {
            root.commitDataList = newCommitList
            root.loadData()
        }
    }

    // Helper function to update branches and tags for a single commit
    function updateBranchesAndTags(commit) {
        // Update branches
        if (commit.branchNames && Array.isArray(commit.branchNames)) {
            var existingBranches = {};
            for (var b = 0; b < branches.count; b++) {
                existingBranches[branches.get(b).name] = true;
            }

            for (var i = 0; i < commit.branchNames.length; i++) {
                var branchName = commit.branchNames[i];
                if (!existingBranches[branchName]) {
                    branches.append({
                        name: branchName,
                        color: GraphUtils.getBranchColor(branchName),
                        isCurrent: branchName === "main"
                    });
                }
            }
        }

        // Update tags
        if (commit.tagNames && Array.isArray(commit.tagNames)) {
            var existingTags = {};
            for (var t = 0; t < tags.count; t++) {
                existingTags[tags.get(t).name] = true;
            }

            for (var j = 0; j < commit.tagNames.length; j++) {
                var tagName = commit.tagNames[j];
                if (!existingTags[tagName]) {
                    tags.append({
                        name: tagName,
                        color: GraphUtils.getTagColor(tagName),
                        commitHash: commit.hash
                    });
                }
            }
        }
    }

    // Load data from commitDataList or generate dummy data
    function loadData() {
        commits.clear();
        branches.clear();
        tags.clear();

        var commitData = [];

        // If commitDataList is provided, use it.
        if (commitDataList && commitDataList.length > 0) {
            commitData = commitDataList;
        } else {
            return;
        }

        // Store full data array (ListModel doesn't preserve arrays)
        // Reverse array so newest is at index 0 (will be displayed at top)
        root.commitDataArray = commitData.slice().reverse();

        // Process all commits to extract branches and tags
        for (var i = 0; i < commitData.length; i++) {
            updateBranchesAndTags(commitData[i]);
        }

        // Add commits to model in reversed order (newest first) for display
        for (var revIdx = commitData.length - 1; revIdx >= 0; revIdx--) {
            commits.append(commitData[revIdx]);
        }

        commitPositions = GraphLayout.calculateDAGPositions(root.commitDataArray, root.columnSpacing, root.commitItemHeight, root.itemsSpacing)
    }


    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: 30

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                anchors.left: parent.left
                spacing: 0

                Rectangle {
                    Layout.preferredWidth: root.commitsColGraphWidth
                    Layout.fillHeight: true
                    color: "transparent"

                    Rectangle {
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.bottom: parent.bottom
                        width: 1
                        color: "#f2f2f2"

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.SizeHorCursor

                            property real startX: 0
                            property int startWidth: 0

                            onPressed: {
                                startX = mouse.x
                                startWidth = root.commitsColGraphWidth
                            }

                            onPositionChanged: {
                                if (!pressed) return

                                var delta = mouse.x - startX
                                var newWidth = startWidth + delta
                                root.commitsColGraphWidth =Math.max(80, newWidth)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: root.commitsColBranchTagWidth
                    Layout.fillHeight: true
                    color: "transparent"

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
                        color: "#f2f2f2"

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.SizeHorCursor

                            property real startX: 0
                            property int startWidth: 0

                            onPressed: {
                                startX = mouse.x
                                startWidth = root.commitsColBranchTagWidth
                            }

                            onPositionChanged: {
                                if (!pressed) return

                                var delta = mouse.x - startX
                                var newWidth = startWidth + delta
                                root.commitsColBranchTagWidth = Math.max(80, newWidth)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: root.commitsColMessageWidth
                    Layout.fillHeight: true
                    color: "transparent"

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
                        color: "#f2f2f2"

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.SizeHorCursor

                            property real startX: 0
                            property int startWidth: 0

                            onPressed: {
                                startX = mouse.x
                                startWidth = root.commitsColMessageWidth
                            }

                            onPositionChanged: {
                                if (!pressed) return

                                var delta = mouse.x - startX
                                var newWidth = startWidth + delta
                                root.commitsColMessageWidth = Math.max(80, newWidth)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: root.commitsColAuthorWidth
                    Layout.fillHeight: true
                    color: "transparent"

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
                        color: "#f2f2f2"

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.SizeHorCursor

                            property real startX: 0
                            property int startWidth: 0

                            onPressed: {
                                startX = mouse.x
                                startWidth = root.commitsColAuthorWidth
                            }

                            onPositionChanged: {
                                if (!pressed) return

                                var delta = mouse.x - startX
                                var newWidth = startWidth + delta
                                root.commitsColAuthorWidth = Math.max(80, newWidth)
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.preferredWidth: root.commitsColDateWidth
                    Layout.fillHeight: true
                    Layout.alignment: Qt.AlignRight
                    color: "transparent"

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

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 2
                color: "#f2f2f2"
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
                        if (root.commitDataArray.length === 0) return width
                        var maxCols = 0
                        for (var i = 0; i < root.commitDataArray.length; i++) {
                            var commit = root.commitDataArray[i]
                            var pos = root.commitPositions[commit.hash]
                            if (pos && pos.column > maxCols) {
                                maxCols = pos.column
                            }
                        }
                        var minWidth = 40 + (maxCols + 1) * root.columnSpacing + 300
                        return Math.max(width, minWidth)
                    }
                    contentHeight: Math.max(height, root.commitDataArray.length * (root.commitItemHeight + (itemsSpacing * 2)))
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
                        height: root.commitDataArray.length * (root.commitItemHeight+ (itemsSpacing * 2))

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
                            function onCommitDataArrayChanged() {
                                var newHeight = Math.max(graphFlickable.height, root.commitDataArray.length * (root.commitItemHeight + (itemsSpacing * 2)))
                                graphCanvas.height = newHeight
                                graphFlickable.contentHeight = newHeight
                                graphCanvas.requestPaint()
                                // Force contentWidth recalculation
                                graphFlickable.contentWidth = Qt.binding(function() {
                                    if (root.commitDataArray.length === 0) return graphFlickable.width
                                    var maxCols = 0
                                    for (var i = 0; i < root.commitDataArray.length; i++) {
                                        var commit = root.commitDataArray[i]
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

                        property var svgImage: Image {
                            source: "qrc:/GitEase/Resources/Images/defaultUserIcon.svg"
                            anchors.centerIn: parent
                            height: 14.5
                            width: 14.5
                        }

                        onPaint: {
                            var ctx = getContext("2d");
                            ctx.clearRect(0, 0, width, height);
                            ctx.globalAlpha = 1.0;

                            if (root.commitDataArray.length === 0) return;

                            // Calculate center offset for graph
                            var maxColumns = 0;
                            for (var i = 0; i < root.commitDataArray.length; i++) {
                                var commit = root.commitDataArray[i];
                                var pos = root.commitPositions[commit.hash];
                                if (pos && pos.column > maxColumns) {
                                    maxColumns = pos.column;
                                }
                            }

                            // Start graph from left side
                            var centerOffset = root.columnSpacing / 2; // Padding from left edge

                            var branchLatestCommit = {};
                            var newerInBranchByCommit = {};
                            var lastSeenByBranch = {};

                            for (var j = 0; j < root.commitDataArray.length; j++) {
                                var c0 = root.commitDataArray[j];
                                var b0 = (c0 && c0.branchNames && c0.branchNames.length > 0) ? c0.branchNames[0] : "main";
                                if (!branchLatestCommit[b0]) branchLatestCommit[b0] = c0.hash;
                                if (lastSeenByBranch[b0]) newerInBranchByCommit[c0.hash] = lastSeenByBranch[b0];
                                lastSeenByBranch[b0] = c0.hash;
                            }

                            for (var j = 0; j < root.commitDataArray.length; j++) {
                                var commit2 = root.commitDataArray[j];
                                var pos2 = root.commitPositions[commit2.hash];
                                if (!pos2) continue;

                                var centerX = centerOffset + pos2.column * root.columnSpacing + root.columnSpacing / 2;
                                var centerY = pos2.y + root.commitItemHeight / 2;

                                var commitBranchName = (commit2.branchNames && commit2.branchNames.length > 0) ? commit2.branchNames[0] : "main";
                                var newerHash = newerInBranchByCommit[commit2.hash];
                                if (newerHash) {
                                    var newerPos = root.commitPositions[newerHash];
                                    if (newerPos) {
                                        var newerX = centerOffset + newerPos.column * root.columnSpacing + root.columnSpacing / 2;
                                        var newerY = newerPos.y + root.commitItemHeight / 2;
                                        var branchObj2 = GraphUtils.findInListModel(root.branches, "name", commitBranchName);
                                        var branchColor2 = branchObj2 ? branchObj2.color : "#4a9eff";

                                        ctx.save();
                                        ctx.strokeStyle = branchColor2;
                                        ctx.globalAlpha = 0.9;
                                        ctx.lineWidth = 2.5;

                                        var lineOffset = 0; // Use center points instead of offset
                                        if (newerPos.column !== pos2.column) {
                                            // Draw curved line for column changes from center to center
                                            ctx.beginPath();
                                            ctx.moveTo(newerX, newerY);

                                            // Create smooth curve from center to center
                                            var controlX = (newerX + centerX) / 2;
                                            var controlY = (newerY + centerY) / 2;
                                            ctx.quadraticCurveTo(controlX, controlY, centerX, centerY);
                                            ctx.stroke();
                                        } else {
                                            ctx.beginPath();
                                            ctx.moveTo(centerX, newerY);
                                            ctx.lineTo(centerX, centerY);
                                            ctx.stroke();
                                        }
                                        ctx.restore();
                                    }
                                }

                                // Handle merge and checkout situations
                                if ((commit2.commitType === "checkout" || commit2.commitType === "merge") && commit2.parentHashes) {
                                    var parentHashesArray = commit2.parentHashes;
                                    if (Array.isArray(parentHashesArray)) {
                                        for (var pIdx = 0; pIdx < parentHashesArray.length; pIdx++) {
                                            var parentHash = parentHashesArray[pIdx];
                                            var parentPos = root.commitPositions[parentHash];
                                            if (!parentPos) continue;

                                            var parentX = centerOffset + parentPos.column * root.columnSpacing + root.columnSpacing / 2;
                                            var parentY = parentPos.y + root.commitItemHeight / 2;

                                            // For checkout, use current commit's branch color, not parent's
                                            var lineColor;
                                            if (commit2.commitType === "checkout") {
                                                var currentBranchName = (commit2.branchNames && commit2.branchNames.length > 0) ? commit2.branchNames[0] : "main";
                                                var currentBranchObj = GraphUtils.findInListModel(root.branches, "name", currentBranchName);
                                                lineColor = currentBranchObj ? currentBranchObj.color : "#4a9eff";
                                            } else {
                                                // For merge, use parent branch color
                                                var parentBranchName = parentPos.branchName || "main";
                                                var parentBranchObj = GraphUtils.findInListModel(root.branches, "name", parentBranchName);
                                                lineColor = parentBranchObj ? parentBranchObj.color : "#4a9eff";
                                            }

                                            ctx.save();
                                            ctx.strokeStyle = lineColor;
                                            ctx.globalAlpha = 2.5;
                                            ctx.lineWidth = 2.5;

                                            ctx.beginPath();

                                            if (parentPos.column !== pos2.column) {
                                                // Different columns: draw L-shaped line from center to center
                                                // Start from exact center of parent
                                                ctx.moveTo(parentX, parentY);

                                                // Go horizontally to the middle point (aligned with parent Y)
                                                var midX = parentX + (centerX - parentX);
                                                ctx.lineTo(midX, parentY);

                                                // Go vertically to align with target Y
                                                ctx.lineTo(midX, centerY);

                                                // Go horizontally to exact center of target
                                                ctx.lineTo(centerX, centerY);
                                            } else {
                                                // Same column: straight line from center to center
                                                ctx.moveTo(parentX, parentY);
                                                ctx.lineTo(centerX, centerY);
                                            }

                                            ctx.stroke();
                                            ctx.restore();
                                        }
                                    }
                                }
                            }

                            // First pass: Draw lines from nodes to branch/tag labels (only for HEAD commits)
                            for (var lineIdx = 0; lineIdx < root.commitDataArray.length; lineIdx++) {
                                var commitForLine = root.commitDataArray[lineIdx];
                                var posForLine = root.commitPositions[commitForLine.hash];
                                if (!posForLine) continue;

                                // Check if this is a HEAD commit
                                var laneBranchName = posForLine.branchName || (commitForLine.branchNames && commitForLine.branchNames.length > 0 ? commitForLine.branchNames[0] : "main");
                                var isHeadCommitForLabels = branchLatestCommit && branchLatestCommit[laneBranchName] === commitForLine.hash;

                                // Only show labels for HEAD commits
                                if (!isHeadCommitForLabels) continue;

                                var centerXForLine = centerOffset + posForLine.column * root.columnSpacing + root.columnSpacing / 2;
                                var centerYForLine = posForLine.y + root.commitItemHeight / 2;

                                // Collect all labels (tags first, then branches) for this commit
                                var allLabels = [];

                                // Add tag labels first (left side)
                                if (commitForLine.tagNames && Array.isArray(commitForLine.tagNames)) {
                                    for (var tIdx = 0; tIdx < commitForLine.tagNames.length; tIdx++) {
                                        var tagName = commitForLine.tagNames[tIdx];
                                        var tagObj = GraphUtils.findInListModel(root.tags, "name", tagName);
                                        var tagColor = tagObj ? tagObj.color : "#ff00aa";
                                        allLabels.push({
                                            text: tagName,
                                            color: tagColor
                                        });
                                    }
                                }

                                // Add branch labels last (right side)
                                if (commitForLine.branchNames && Array.isArray(commitForLine.branchNames)) {
                                    for (var bIdx = 0; bIdx < commitForLine.branchNames.length; bIdx++) {
                                        var branchName = commitForLine.branchNames[bIdx];
                                        var branchObj3 = GraphUtils.findInListModel(root.branches, "name", branchName);
                                        var branchColor4 = branchObj3 ? branchObj3.color : "#4a9eff";
                                        var isBranchHead = branchLatestCommit && branchLatestCommit[branchName] === commitForLine.hash;
                                        allLabels.push({
                                            text: isBranchHead ? (branchName + " (HEAD)") : (branchName),
                                            color: branchColor4
                                        });
                                    }
                                }

                                // Draw all labels on same horizontal line
                                if (allLabels.length > 0) {
                                    var labelStartX = centerOffset + (maxColumns + 1) * root.columnSpacing + 50;  // Right side of graph
                                    var labelY = centerYForLine;  // Same Y as node (horizontal line)
                                    var currentLabelX = labelStartX;
                                    var labelSpacing = 8;  // Horizontal spacing between labels

                                    // Draw labels
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

                                    var rightmostLabel = labelPositions[0];
                                    var rightmostLabelX = rightmostLabel.x;

                                    ctx.save();
                                    ctx.strokeStyle = allLabels[0].color;
                                    ctx.globalAlpha = 0.8;
                                    ctx.lineWidth = 5;

                                    ctx.beginPath();
                                    ctx.moveTo(centerXForLine, centerYForLine); // Start from right side of node
                                    ctx.lineTo(rightmostLabelX, labelY); // End at rightmost label
                                    ctx.stroke();
                                    ctx.restore();

                                    currentLabelX = labelStartX;
                                    var labelInfo = allLabels[0];

                                    ctx.font = "bold 11px Arial";
                                    ctx.textAlign = "left";
                                    ctx.textBaseline = "middle";
                                    var textMetrics = ctx.measureText(labelInfo.text);
                                    var labelWidth = textMetrics.width + 16;
                                    var labelHeight = 20;
                                    var labelX = currentLabelX;
                                    var labelRectY = labelY - labelHeight / 2;

                                    ctx.fillStyle = labelInfo.color;
                                    ctx.globalAlpha = 0.95;
                                    GraphUtils.drawRoundedRect(ctx, labelX, labelRectY, labelWidth, labelHeight, 2);
                                    ctx.fill();

                                    // Enhanced label styling with better contrast
                                    var contrastColor = GraphUtils.getContrastColor(labelInfo.color);
                                    ctx.fillStyle = contrastColor;
                                    ctx.globalAlpha = 1.0;
                                    ctx.font = "bold 11px 'Segoe UI', Arial, sans-serif";
                                    ctx.fillText(labelInfo.text, labelX + 8, labelY);
                                    ctx.restore();

                                    currentLabelX += labelWidth + labelSpacing;
                                }
                            }

                            // Second pass: Draw commit nodes (on top of lines)
                            for (var k = 0; k < root.commitDataArray.length; k++) {
                                var commit3 = root.commitDataArray[k];
                                var pos3 = root.commitPositions[commit3.hash];
                                if (!pos3) continue;

                                var centerX2 = centerOffset + pos3.column * root.columnSpacing + root.columnSpacing / 2;
                                var centerY2 = pos3.y + root.commitItemHeight / 2;

                                var laneBranchName = pos3.branchName || (commit3.branchNames && commit3.branchNames.length > 0 ? commit3.branchNames[0] : "main");
                                var branchObj = GraphUtils.findInListModel(root.branches, "name", laneBranchName);
                                var branchColor3 = branchObj ? branchObj.color : "#4a9eff";

                                var isHeadCommit = branchLatestCommit && branchLatestCommit[laneBranchName] === commit3.hash;

                                var isSelected = root.selectedCommit && root.selectedCommit.hash === commit3.hash;
                                var avatarSize = root.commitItemHeight;
                                var avatarRadius = avatarSize / 2;

                                var lighterBranchColor = GraphUtils.lightenColor(branchColor3, 0.4);
                                var darkerBranchColor = GraphUtils.darkenColor(branchColor3, 0.2);

                                ctx.strokeStyle = isSelected ? "#aad711" : GraphUtils.lightenColor(branchColor3, 0.6);
                                ctx.lineWidth = isSelected ? 4 : 2.5;

                                ctx.beginPath();
                                ctx.arc(centerX2, centerY2, avatarRadius, 0, 2 * Math.PI);
                                ctx.fillStyle = "#D9D9D9";
                                ctx.fill();
                                ctx.stroke();

                                // Draw avatar icon with fallback
                                ctx.save();
                                ctx.fillStyle = "#ffffff";
                                ctx.font = (avatarSize * 0.8) + "px Arial";
                                ctx.textAlign = "center";
                                ctx.textBaseline = "middle";

                                var drawX = centerX2 - svgImage.width / 2;
                                var drawY = centerY2 - svgImage.height / 2;

                                ctx.drawImage(svgImage, drawX, drawY);
                                ctx.stroke();
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
                    height: root.commitItemHeight + itemsSpacing + itemsSpacing

                    property var commitData: model

                    RowLayout {
                        anchors.fill: parent
                        spacing: 0
                        anchors.topMargin: itemsSpacing
                        anchors.bottomMargin: itemsSpacing

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
                                    Layout.preferredWidth: 3
                                    Layout.preferredHeight: commitItemHeight * 0.8
                                    Layout.alignment: Qt.AlignVCenter
                                    radius: 6
                                    color: {
                                        // TODO : fix bug and find set color
                                        "#ededed"
                                        // GraphUtils.getBranchColor(commitData.branchNames)
                                    }
                                }

                                Label {
                                    text: commitData.message || ""
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
                                    text: GraphUtils.formatDate(commitData.timestamp) + " " + GraphUtils.formatTime(commitData.timestamp)
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
                            root.commitClicked(commitData.id)
                        }
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        // Initialize simulator with some data if no data exists
        if (commitDataList.length === 0) {
            // Add an initial branch
            branches.append({
                name: "main",
                isCurrent: true,
                isLocal: true,
                isRemote: false,
                upstream: "",
                ahead: 0,
                behind: 0,
                commitHash: ""
            })

            // Enable simulator
            simulator.enabled = true
            simulator.intervalMs = 2000  // Speed up simulation for testing

            // Add initial commit
            var now = new Date().toISOString()
            var initialCommit = {
                id: "initial_commit",
                hash: "initial_commit",
                shortHash: "initial",
                message: "Initial commit",
                author: "System",
                email: "system@example.com",
                date: now,
                timestamp: now,
                branchNames: ["main"],
                tagNames: [],
                parentHashes: [],
                commitType: "normal"
            }
            commitDataList = [initialCommit]
            loadData() // Call loadData to process the initial commit
        } else {
            // Load existing data
            loadData()
        }
    }
}
