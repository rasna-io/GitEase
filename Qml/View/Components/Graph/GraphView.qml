import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

import "qrc:/GitEase/Qml/Core/Scripts/GraphLayout.js" as GraphLayout
import "qrc:/GitEase/Qml/Core/Scripts/GraphUtils.js" as GraphUtils

/*! ***********************************************************************************************
 * GraphView Component
 * Displays the git graph visualization with branch/tag labels
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property var commits
    property string       selectedCommitHash:    ""
    property string       hoveredCommitHash:     ""
    property bool         showAvatar:            true

    property string       emptyStateDetailsText: ""

    // Graph display properties
    property int          commitItemHeight:      24
    property int          commitItemSpacing:     4
    property int          columnSpacing:         30

    // Internal calculated properties
    property var          commitPositions:       ({})
    property var          allCommitsHash:        ({})

    // Column widths
    property int          graphWidth:            30
    property int          branchTagWidth:        30
    readonly property int minGraphWidth:         60
    readonly property int minBranchTagWidth:     80

    /* Signals
     * ****************************************************************************************/
    signal scrollPositionChanged(real contentY, real contentHeight, real height)
    signal graphWidthResized(int newGraphWidth, int newBranchTagWidth)
    signal commitSelected(string commitHash)
    signal commitHovered(string commitHash)

    /* Functions
     * ****************************************************************************************/
    function commitColor(commitObj) {
        if (!commitObj || !commitObj.colorKey)
            return GraphUtils.getCategoryColor()
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

    function requestPaint() {
        graphCanvas.requestPaint()
    }

    function setContentY(y) {
        graphFlickable.syncScroll = true
        graphFlickable.contentY = y
        graphFlickable.syncScroll = false
    }

    /* Connections & Event Handlers
     * ****************************************************************************************/
    onCommitsChanged: {
        // Build allCommitsHash lookup
        root.allCommitsHash = {}
        for (let i = 0; i < root.commits.length; i++) {
            root.allCommitsHash[root.commits[i].hash] = root.commits[i]
        }

        // Calculate commit positions using GraphLayout
        root.commitPositions = GraphLayout.calculateDAGPositions(
            root.commits,
            root.columnSpacing,
            root.commitItemHeight,
            root.commitItemSpacing
        )

        let newHeight = Math.max(graphFlickable.height, root.commits.length * (root.commitItemHeight + (root.commitItemSpacing * 2)))
        graphCanvas.height = newHeight
        graphFlickable.contentHeight = newHeight
        
        // Calculate contentWidth once instead of binding
        if (root.commits.length === 0) {
            graphFlickable.contentWidth = graphFlickable.width
        } else {
            let maxCols = 0
            for (let i = 0; i < root.commits.length; i++) {
                let commit = root.commits[i]
                let pos = root.commitPositions[commit.hash]
                if (pos && pos.column > maxCols) {
                    maxCols = pos.column
                }
            }
            let minWidth = 40 + (maxCols + 1) * root.columnSpacing + 300
            graphFlickable.contentWidth = Math.max(graphFlickable.width, minWidth)
        }
        
        graphCanvas.requestPaint()
    }

    onSelectedCommitHashChanged: graphCanvas.requestPaint()

    onHoveredCommitHashChanged: graphCanvas.requestPaint()

    onGraphWidthChanged: graphCanvas.requestPaint()

    Connections {
        target: Style
        function onCurrentThemeChanged() {
            graphCanvas.requestPaint()
        }
    }

    /* Children
     * ****************************************************************************************/
    // Empty state (no commits to render)
    EmptyStateView {
        title: "no commit to draw graph"
        details: root.emptyStateDetailsText
        visible: !root.commits || root.commits.length === 0
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Header
        Rectangle {
            id: header
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            color: Style.colors.primaryBackground
            visible: root.commits && root.commits.length > 0

            RowLayout {
                anchors.fill: parent
                spacing: 0

                // Graph Column Header
                Rectangle {
                    Layout.preferredWidth: root.graphWidth
                    Layout.fillHeight: true
                    color: graphHeaderMouseArea.containsMouse ? Style.colors.hoverTitle : "transparent"
                    
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
                        color: graphDividerMouseArea.pressed ? Style.colors.resizeHandlePressed : Style.colors.resizeHandle

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
                                startWidth = root.graphWidth
                            }

                            onPositionChanged: function(mouse) {
                                if (!pressed) return

                                let currentX = mouseX + mapToItem(header, 0, 0).x
                                let delta = currentX - startX
                                
                                let newWidth = Math.max(root.minGraphWidth, startWidth + delta)
                                let actualDelta = newWidth - root.graphWidth
                                
                                let newBranchTagWidth = root.branchTagWidth - actualDelta
                                
                                if (newBranchTagWidth < root.minBranchTagWidth) {
                                    newBranchTagWidth = root.minBranchTagWidth
                                    newWidth = root.graphWidth + (root.branchTagWidth - root.minBranchTagWidth)
                                }
                                
                                if (newWidth !== root.graphWidth) {
                                    root.graphWidthResized(newWidth, newBranchTagWidth)
                                }
                            }
                        }
                    }
                }

                // Branch/Tag Column Header
                Rectangle {
                    Layout.preferredWidth: root.branchTagWidth
                    Layout.fillHeight: true
                    color: branchTagHeaderMouseArea.containsMouse ? Style.colors.hoverTitle : "transparent"
                    
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
                        color: Style.colors.foreground
                        font.pixelSize: 11
                        font.bold: true
                        elide: Text.ElideRight
                    }
                }
            }
        }

        // Graph Content
        Rectangle {
            id: graphColumnRect
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: Style.colors.primaryBackground

            Flickable {
                id: graphFlickable
                anchors.fill: parent
                clip: true
                
                contentWidth: width  // Will be set in onCommitsChanged
                contentHeight: Math.max(height, root.commits.length * (root.commitItemHeight + (root.commitItemSpacing * 2)))
                boundsBehavior: Flickable.StopAtBounds

                property bool syncScroll: false

                onContentYChanged: {
                    if (!syncScroll) {
                        root.scrollPositionChanged(contentY, contentHeight, height)
                    }
                }

                Canvas {
                    id: graphCanvas
                    width: graphFlickable.contentWidth
                    height: root.commits.length * (root.commitItemHeight + (root.commitItemSpacing * 2))

                    Component.onCompleted: {
                        graphCanvas.requestPaint()
                    }

                    // Mouse area for detecting hover and clicks on commits
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        propagateComposedEvents: false
                        enabled: root.commits && root.commits.length > 0

                        function getCommitAtPosition(mouseX, mouseY) {
                            // Check if mouse is within any commit row (entire row height)
                            for (let i = 0; i < root.commits.length; i++) {
                                let commit = root.commits[i]
                                let pos = root.commitPositions[commit.hash]
                                if (!pos) continue

                                // Check if mouse Y is within the row bounds
                                let rowTop = pos.y
                                let rowBottom = pos.y + root.commitItemHeight + (root.commitItemSpacing * 2)

                                if (mouseY >= rowTop && mouseY < rowBottom) {
                                    return commit.hash
                                }
                            }
                            return ""
                        }

                        onPositionChanged: function(mouse) {
                            if (!mouse || !root.commits || root.commits.length === 0) return
                            let commitHash = getCommitAtPosition(mouse.x, mouse.y)
                            if (commitHash.length > 0) {
                                if (!root.hoveredCommitHash || root.hoveredCommitHash !== commitHash) {
                                    root.commitHovered(commitHash)
                                }
                            }
                        }

                        onExited: {
                            if (root.hoveredCommitHash.length > 0) {
                                root.commitHovered("")
                            }
                        }

                        onClicked: function(mouse) {
                            if (!mouse || !root.commits || root.commits.length === 0) return
                            let commitHash = getCommitAtPosition(mouse.x, mouse.y)
                            if (commitHash.length > 0) {
                                root.commitSelected(commitHash)
                            }
                        }
                    }

                    property var svgImage: Image {
                        source: "qrc:/GitEase/Resources/Images/defaultUserIcon.svg"
                        anchors.centerIn: parent
                        height: 14.5
                        width: 14.5
                    }

                    onPaint: {
                        let ctx = getContext("2d");

                        ctx.clearRect(0, 0, width, height);
                        ctx.globalAlpha = 1.0;
                        ctx.fillStyle = Style.colors.primaryBackground;
                        ctx.fillRect(0, 0, width, height);
                        
                        if (!root.commits || root.commits.length === 0)
                            return;

                        let centerOffset = root.columnSpacing / 2;

                        let branchLatestCommit = {};
                        for (let i = 0; i < root.commits.length; i++) {
                            let commit = root.commits[i];
                            if (commit && commit.branchNames && commit.branchNames.length > 0) {
                                for (let j = 0; j < commit.branchNames.length; j++) {
                                    let branchName = commit.branchNames[j];
                                    if (branchName)
                                        branchLatestCommit[branchName] = commit.hash;
                                }
                            }
                        }
                        
                        let commitByHash = {}
                        let parentInSameLane = {};
                        let crossLaneEdges = [];
                        
                        for (let i = 0; i < root.commits.length; i++) {
                            let commit = root.commits[i];
                            if (commit && commit.hash)
                                commitByHash[commit.hash] = commit

                            let commitPosition = root.commitPositions[commit.hash];
                            if (!commitPosition)
                                continue;

                            let isSelected = root.selectedCommitHash === commit.hash;
                            let isHovered = root.hoveredCommitHash === commit.hash;

                            if (isSelected) {
                                ctx.fillStyle = "#6088B2DF";
                                ctx.fillRect(0, commitPosition.y, graphCanvas.width, root.commitItemHeight + (root.commitItemSpacing * 2));
                            } else if (isHovered) {
                                ctx.fillStyle = Style.colors.hoverTitle;
                                ctx.fillRect(0, commitPosition.y, graphCanvas.width, root.commitItemHeight + (root.commitItemSpacing * 2));
                            }

                            if (!commit.parentHashes)
                                continue;
                            
                            for (let p = 0; p < commit.parentHashes.length; p++) {
                                let parentHash = commit.parentHashes[p];
                                let parentPos = root.commitPositions[parentHash];
                                if (!parentPos) continue;
                                
                                if (parentPos.column === commitPosition.column) {
                                    if (!parentInSameLane[commit.hash]) {
                                        parentInSameLane[commit.hash] = parentHash;
                                    }
                                } else {
                                    let isMerge = commit.commitType === "merge";
                                    crossLaneEdges.push({
                                        from: isMerge ? parentHash : commit.hash,
                                        to: isMerge ? commit.hash : parentHash,
                                        fromPos: isMerge ? parentPos : commitPosition,
                                        toPos: isMerge ? commitPosition : parentPos,
                                        isMerge: isMerge
                                    });
                                }
                            }
                        }

                        // PHASE 1: Draw cross-lane edges
                        for (let edgeIdx = 0; edgeIdx < crossLaneEdges.length; edgeIdx++) {
                            let edge = crossLaneEdges[edgeIdx];
                            let fromPos = edge.fromPos;
                            let toPos = edge.toPos;

                            let fromX = centerOffset + fromPos.column * root.columnSpacing + root.columnSpacing / 2;
                            let fromY = fromPos.y + root.commitItemHeight / 2 + root.commitItemSpacing;
                            let toX = centerOffset + toPos.column * root.columnSpacing + root.columnSpacing / 2;
                            let toY = toPos.y + root.commitItemHeight / 2 + root.commitItemSpacing;

                            let edgeColorVal = edgeColor(edge, commitByHash)

                            ctx.save();
                            ctx.strokeStyle = edgeColorVal;
                            ctx.globalAlpha = 0.85;
                            ctx.lineWidth = 2.5;

                            ctx.beginPath();
                            ctx.moveTo(fromX, fromY);

                            let verticalDistance = Math.abs(toY - fromY);
                            let horizontalDistance = Math.abs(toX - fromX);
                            let controlOffset = Math.min(verticalDistance * 0.6, 40);

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

                        // // PHASE 2: Draw continuation lines
                        for (let j = 0; j < root.commits.length; j++) {
                            let commit = root.commits[j];

                            let branchColor = commitColor(commit);

                            let commitPosition = root.commitPositions[commit.hash];
                            if (commitPosition) {
                                let commitPosCenterX = centerOffset + commitPosition.column * root.columnSpacing + root.columnSpacing / 2;
                                let commitPosCenterY = commitPosition.y + root.commitItemHeight / 2 + root.commitItemSpacing;

                                let parentHash = parentInSameLane[commit.hash];
                                if (parentHash) {
                                    let parentPos = root.commitPositions[parentHash];
                                    if (parentPos) {
                                        let parentX = centerOffset + parentPos.column * root.columnSpacing + root.columnSpacing / 2;
                                        let parentY = parentPos.y + root.commitItemHeight / 2 + root.commitItemSpacing;

                                        ctx.save();
                                        ctx.strokeStyle = branchColor;
                                        ctx.globalAlpha = 0.9;
                                        ctx.lineWidth = 2.5;

                                        ctx.beginPath();
                                        ctx.moveTo(commitPosCenterX, commitPosCenterY);
                                        ctx.lineTo(parentX, parentY);
                                        ctx.stroke();
                                        ctx.restore();
                                    }
                                } else {
                                    let canDraw = false
                                    for(let i = 0; i < commit.parentHashes.length; i++){
                                        if(!allCommitsHash[commit.parentHashes[i]]){
                                            canDraw = true
                                            break
                                        }
                                    }

                                    if(canDraw){
                                        ctx.save();
                                        ctx.strokeStyle = branchColor;
                                        ctx.globalAlpha = 0.9;
                                        ctx.lineWidth = 2.5;

                                        ctx.beginPath();
                                        ctx.moveTo(commitPosCenterX, commitPosCenterY);
                                        ctx.lineTo(commitPosCenterX, graphCanvas.height);
                                        ctx.stroke();
                                        ctx.restore();
                                    }
                                }

                                let isHeadCommitForLabels = false;
                                let headBranchesForThisCommit = [];

                                for (let branchKey in branchLatestCommit) {
                                    if (branchLatestCommit[branchKey] === commit.hash) {
                                        isHeadCommitForLabels = true;
                                        headBranchesForThisCommit.push(branchKey);
                                    }
                                }

                                if (isHeadCommitForLabels){
                                    let allLabels = [];

                                    if (commit.tagNames && commit.tagNames.length > 0) {
                                        for (let tIdx = 0; tIdx < commit.tagNames.length; tIdx++) {
                                            let tagName = commit.tagNames[tIdx];
                                            allLabels.push({
                                                text: tagName,
                                                color: branchColor
                                            });
                                        }
                                    }

                                    for (let i = 0; i < headBranchesForThisCommit.length; i++) {
                                        let headBranchName = headBranchesForThisCommit[i];
                                        allLabels.push({
                                            text: headBranchName + " (HEAD)",
                                            color: branchColor
                                        });
                                    }

                                    if (allLabels.length > 0) {
                                        let dividerPosition = root.graphWidth + 10;
                                        let nodeEndPosition = commitPosCenterX + 20;
                                        let labelStartX = Math.max(dividerPosition, nodeEndPosition);
                                        let labelY = commitPosCenterY;
                                        let currentLabelX = labelStartX;
                                        let labelSpacing = 8;

                                        let labelPositions = [];
                                        for (let calcIdx = 0; calcIdx < allLabels.length; calcIdx++) {
                                            let calcLabelInfo = allLabels[calcIdx];
                                            ctx.font = "bold 11px Arial";
                                            ctx.textAlign = "left";
                                            let calcTextMetrics = ctx.measureText(calcLabelInfo.text);
                                            let calcLabelWidth = calcTextMetrics.width + 16;
                                            labelPositions.push({
                                                x: currentLabelX,
                                                width: calcLabelWidth,
                                                info: calcLabelInfo
                                            });
                                            currentLabelX += calcLabelWidth + labelSpacing;
                                        }

                                        if (labelPositions.length > 0) {
                                            let firstLabel = labelPositions[0];
                                            let lastLabel = labelPositions[labelPositions.length - 1];
                                            let lineEndX = lastLabel.x + lastLabel.width;

                                            ctx.save();
                                            ctx.strokeStyle = branchColor;
                                            ctx.globalAlpha = 0.8;
                                            ctx.lineWidth = 5;

                                            ctx.beginPath();
                                            ctx.moveTo(commitPosCenterX, commitPosCenterY);
                                            ctx.lineTo(lineEndX, labelY);
                                            ctx.stroke();
                                            ctx.restore();
                                        }

                                        for (let labelDrawIdx = 0; labelDrawIdx < labelPositions.length; labelDrawIdx++) {
                                            let labelPos = labelPositions[labelDrawIdx];
                                            let labelInfo = labelPos.info;
                                            let labelX = labelPos.x;
                                            let labelWidth = labelPos.width;
                                            let labelHeight = 20;
                                            let labelRectY = labelY - labelHeight / 2;

                                            ctx.save();
                                            ctx.fillStyle = labelInfo.color;
                                            ctx.globalAlpha = 0.95;
                                            GraphUtils.drawRoundedRect(ctx, labelX, labelRectY, labelWidth, labelHeight, 2);
                                            ctx.fill();

                                            let contrastColor = GraphUtils.getContrastColor(labelInfo.color);
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

                                let isHeadCommit = false;
                                if (commit.branchNames && commit.branchNames.length) {
                                    for (let hb = 0; hb < commit.branchNames.length; hb++) {
                                        let bname = commit.branchNames[hb]
                                        if (branchLatestCommit && branchLatestCommit[bname] === commit.hash) {
                                            isHeadCommit = true;
                                            break;
                                        }
                                    }
                                }

                                let avatarSize = showAvatar ? root.commitItemHeight : 10;
                                let avatarRadius = avatarSize / 2;

                                ctx.save();

                                let isSelected = root.selectedCommitHash === commit.hash;
                                ctx.strokeStyle = isSelected ? GraphUtils.darkenColor(branchColor, 0.2): GraphUtils.lightenColor(branchColor, 0.3);
                                ctx.lineWidth = isSelected ? 4 : 2.5;

                                ctx.beginPath();
                                ctx.arc(commitPosCenterX, commitPosCenterY, avatarRadius, 0, 2 * Math.PI);
                                ctx.fillStyle = showAvatar ? "#D9D9D9" : GraphUtils.lightenColor(branchColor, 0.3);
                                ctx.fill();
                                ctx.stroke();

                                if (showAvatar) {
                                    ctx.fillStyle = "#ffffff";
                                    ctx.font = (avatarSize * 0.8) + "px Arial";
                                    ctx.textAlign = "center";
                                    ctx.textBaseline = "middle";

                                    let drawX = commitPosCenterX - svgImage.width / 2;
                                    let drawY = commitPosCenterY - svgImage.height / 2;
                                    ctx.drawImage(svgImage, drawX, drawY);
                                }
                                ctx.restore();
                            }
                        }
                    }
                }
            }
        }
    }
}
