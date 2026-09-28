import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GitEase_Style
import GitEase_Style_Impl
import "qrc:/GitEase/Qml/Core/Scripts/GraphUtils.js" as GraphUtils

/*! ***********************************************************************************************
 * CommitGraphCanvas – outer Item (layout-friendly) + internal Flickable + Canvas
 *
 * Properties to bind from parent:
 *   commits, commitPositions, columnSpacing, commitItemHeight, commitItemSpacing
 *   selectedHashes, headHash, showAvatar, allCommitsHash
 *   graphColumnWidth, branchTagColumnWidth (for label positioning)
 *   onInfiniteScroll() signal – fired when near bottom
 * ************************************************************************************************/
Item {
    id: root

    /*! ***********************************************************************************************
     * Property Declarations
     * ************************************************************************************************/

    property var    commits             : []
    property var    commitPositions     : ({})
    property int    columnSpacing       : 30
    property int    commitItemHeight    : 24
    property int    commitItemSpacing   : 4
    property var    selectedHashes      : []
    property string headHash            : ""
    property bool   showAvatar          : true
    property real   graphColumnWidth    : 60
    property real   branchTagColumnWidth: 80
    property var    allCommitsHash      : ({})

    property real   viewportY           : 0
    property real   graphContentHeight  : Math.max(height, commits.length * rowHeight)
    readonly property int rowHeight     : commitItemHeight + commitItemSpacing * 2

    property int    hoveredIndex        : -1
    property var    renderCache         : ({
        commitsHash: ({}),
        commitByHash: ({}),
        branchLatestCommit: ({}),
        parentInSameLane: ({}),
        crossLaneEdges: []
    })

    /* Signals
     * ****************************************************************************************/
    signal infiniteScroll()
    signal hoverIndexChanged(int index)
    signal commitRightClicked(int index, real mouseX, real mouseY)

    onCommitsChanged: {
        rebuildRenderCache()
    }
    onCommitPositionsChanged: rebuildRenderCache()

    /* Children
     * ****************************************************************************************/
    Item {
        id: flick
        anchors.fill: parent
        clip: true

        MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.RightButton
            z: 1000

            onPositionChanged: (mouse) => {
                var newHoveredIndex = rowIndexAt(mouse.y + root.viewportY);
                if (newHoveredIndex !== root.hoveredIndex)
                    root.hoverIndexChanged(newHoveredIndex);
            }

            onExited: {
                if (root.hoveredIndex !== -1)
                    root.hoverIndexChanged(-1);
            }

            onClicked: (mouse) => {
                if (mouse.button !== Qt.RightButton)
                    return;
                var idx = rowIndexAt(mouse.y + root.viewportY);
                if (idx < 0)
                    return;
                var pos = hoverArea.mapToItem(root, mouse.x, mouse.y);
                root.commitRightClicked(idx, pos.x, pos.y);
            }
        }

        // ---------- Canvas (draws the entire DAG) ----------
        Canvas {
            id: graphCanvas
            anchors.fill: parent

            property int lastHoveredIndex: -1
            property int scrollRepaintRequest: -1

            canvasSize: Qt.size(width, root.graphContentHeight)
            tileSize: Qt.size(Math.max(1, Math.ceil(width)), 1024)
            canvasWindow: Qt.rect(0, root.viewportY, width, height)

            property var svgImage: Image {
                source: "qrc:/GitEase/Resources/Images/defaultUserIcon.svg"
                anchors.centerIn: parent
                height: 14.5; width: 14.5
            }

            // Trigger repaint when data changes
            Connections {
                target: root
                function onSelectedHashesChanged() { graphCanvas.invalidateAll() }
                function onHoveredIndexChanged() {
                    graphCanvas.invalidateRow(graphCanvas.lastHoveredIndex)
                    graphCanvas.invalidateRow(root.hoveredIndex)
                    graphCanvas.lastHoveredIndex = root.hoveredIndex
                }
            }

            function invalidateRow(index) {
                if (index < 0 || index >= root.commits.length)
                    return
                markDirty(Qt.rect(0, index * root.rowHeight, canvasSize.width, root.rowHeight))
            }

            function invalidateAll() {
                if (!available)
                    return

                markDirty(Qt.rect(0, 0, canvasSize.width, canvasSize.height))
            }

            function scheduleVisibleRepaint() {
                if (!available || scrollRepaintRequest !== -1)
                    return

                scrollRepaintRequest = requestAnimationFrame(function() {
                    scrollRepaintRequest = -1
                    markDirty(graphCanvas.canvasWindow)
                })
            }

            onCanvasWindowChanged: scheduleVisibleRepaint()

            onAvailableChanged: {
                if (available) {
                    invalidateAll()
                    scheduleVisibleRepaint()
                }
            }

            Component.onCompleted: {
                lastHoveredIndex = root.hoveredIndex
                invalidateAll()
            }

            onPaint: (region) => {
                var ctx = getContext("2d");
                ctx.clearRect(region.x, region.y, region.width, region.height);

                if (!root.commits || root.commits.length === 0) return;

                var commitsHash = root.renderCache.commitsHash;
                var paintTop = region.y;
                var paintBottom = region.y + region.height;

                // ---- Start of original drawing logic (adapted) ----

                var centerOffset = root.columnSpacing / 2;

                var commitByHash = root.renderCache.commitByHash;
                var branchLatestCommit = root.renderCache.branchLatestCommit;

                // Helper functions (local for convenience)
                function edgeColor(edge, commitByHash) {
                    if (commitByHash && edge && edge.from) {
                        var fromCommit = commitByHash[edge.from];
                        if (fromCommit && fromCommit.colorKey)
                            return GraphUtils.getCategoryColor(fromCommit.colorKey);
                    }
                    return GraphUtils.getCategoryColor("edge:" + edge.from + ":" + edge.to);
                }
                function isCommitSelected(hash) {
                    return root.selectedHashes && root.selectedHashes.indexOf(hash) !== -1;
                }

                // --- Build edge routing data ---
                var parentInSameLane = root.renderCache.parentInSameLane;
                var crossLaneEdges = root.renderCache.crossLaneEdges;

                // Phase 1: Same-lane straight lines
                for (var j2 = 0; j2 < root.commits.length; j2++) {
                    var commit2 = root.commits[j2];
                    var pos2 = root.commitPositions[commit2.hash];
                    if (!pos2) continue;

                    var centerX = centerOffset + pos2.column * root.columnSpacing + root.columnSpacing / 2;
                    var centerY = pos2.y + root.commitItemHeight / 2 + root.commitItemSpacing;
                    var parentHash = parentInSameLane[commit2.hash];

                    if (parentHash) {
                        var pp = root.commitPositions[parentHash];
                        if (pp) {
                            var parentX = centerOffset + pp.column * root.columnSpacing + root.columnSpacing / 2;
                            var parentY = pp.y + root.commitItemHeight / 2 + root.commitItemSpacing;
                            if (Math.max(centerY, parentY) >= paintTop
                                    && Math.min(centerY, parentY) <= paintBottom) {
                                var branchColor2 = root.commitColor(commit2);

                                ctx.save();
                                ctx.strokeStyle = branchColor2;
                                ctx.globalAlpha = 0.9;
                                ctx.lineWidth = 2.5;
                                if (commit2.isUncommitted) ctx.setLineDash([4, 4]);
                                else ctx.setLineDash([]);
                                ctx.beginPath();
                                ctx.moveTo(centerX, centerY);
                                ctx.lineTo(parentX, parentY);
                                ctx.stroke();
                                ctx.setLineDash([]);
                                ctx.restore();
                            }
                        }
                    }

                    // Independent of the same-lane check above: any parent this commit
                    // has that isn't loaded on the current page(s) at all still needs its
                    // own dangling tail. This matters for merge commits too - e.g. one
                    // parent already resolved to a real same-lane line (or a cross-lane
                    // curve in Phase 2) doesn't mean every parent was found; a second
                    // parent sitting on a page we haven't scrolled to yet must still get
                    // a visible "continues off-page" marker instead of silently vanishing.
                    var canDraw = false;
                    var parentHashes = commit2.parentHashes || [];
                    for (var i2 = 0; i2 < parentHashes.length; i2++) {
                        if (!commitsHash[parentHashes[i2]]) {
                            canDraw = true;
                            break;
                        }
                    }
                    if (canDraw && centerY <= paintBottom && root.graphContentHeight >= paintTop) {
                        // The real parent isn't loaded yet (further down, on a page we
                        // haven't scrolled to), so draw the tail down to the bottom of the
                        // currently loaded content - it leads toward where that parent will
                        // appear once more commits load. GraphLayout.js retires this lane
                        // for good in this case (never reassigns it to an unrelated
                        // commit), so extending the full height is safe: nothing else will
                        // ever render in this column to be falsely read as connected.
                        var stubEndY = root.graphContentHeight;
                        var branchColor2b = root.commitColor(commit2);
                        ctx.save();
                        ctx.strokeStyle = branchColor2b;
                        ctx.globalAlpha = 0.9;
                        ctx.lineWidth = 2.5;
                        ctx.setLineDash([4, 4]);
                        ctx.beginPath();
                        ctx.moveTo(centerX, centerY);
                        ctx.lineTo(centerX, stubEndY);
                        ctx.stroke();
                        ctx.setLineDash([]);
                        ctx.restore();
                    }
                }

                // Phase 2: Cross-lane bezier curves
                for (var edgeIdx = 0; edgeIdx < crossLaneEdges.length; edgeIdx++) {
                    var edge = crossLaneEdges[edgeIdx];
                    var fromPos = edge.fromPos;
                    var toPos = edge.toPos;

                    var fromCenterX = centerOffset + fromPos.column * root.columnSpacing + root.columnSpacing / 2;
                    var fromCenterY = fromPos.y + root.commitItemHeight / 2 + root.commitItemSpacing;
                    var toCenterX = centerOffset + toPos.column * root.columnSpacing + root.columnSpacing / 2;
                    var toCenterY = toPos.y + root.commitItemHeight / 2 + root.commitItemSpacing;

                    if (Math.max(fromCenterY, toCenterY) < paintTop
                            || Math.min(fromCenterY, toCenterY) > paintBottom)
                        continue;

                    var startX = edge.isMerge ? fromCenterX : toCenterX;
                    var startY = edge.isMerge ? fromCenterY : toCenterY;
                    var endX = edge.isMerge ? toCenterX : fromCenterX;
                    var endY = edge.isMerge ? toCenterY : fromCenterY;

                    var edgeColorVal = edgeColor(edge, commitByHash);
                    var deltaX = endX - startX;
                    var deltaY = endY - startY;
                    var curveRadius = Math.min(Math.abs(deltaX) / 2, root.commitItemHeight, Math.abs(deltaY) / 2);
                    curveRadius = Math.max(curveRadius, 8);

                    ctx.save();
                    ctx.strokeStyle = edgeColorVal;
                    ctx.globalAlpha = 0.85;
                    ctx.lineWidth = 2.5;
                    ctx.beginPath();
                    ctx.moveTo(startX, startY);

                    if (deltaX === 0) {
                        ctx.lineTo(endX, endY);
                    } else if (deltaX > 0) {
                        var horizontalEndX = endX - curveRadius;
                        if (deltaY > 0) {
                            ctx.lineTo(horizontalEndX, startY);
                            ctx.quadraticCurveTo(endX, startY, endX, startY + curveRadius);
                            ctx.lineTo(endX, endY);
                        } else {
                            ctx.lineTo(horizontalEndX, startY);
                            ctx.quadraticCurveTo(endX, startY, endX, startY - curveRadius);
                            ctx.lineTo(endX, endY);
                        }
                    } else {
                        if (deltaY > 0) {
                            ctx.lineTo(startX, endY - curveRadius);
                            ctx.quadraticCurveTo(startX, endY, startX - curveRadius, endY);
                            ctx.lineTo(endX, endY);
                        } else {
                            ctx.lineTo(startX, endY + curveRadius);
                            ctx.quadraticCurveTo(startX, endY, startX - curveRadius, endY);
                            ctx.lineTo(endX, endY);
                        }
                    }
                    ctx.stroke();
                    ctx.restore();
                }

                // Phase 3: Branch/Tag labels
                for (var lineIdx = 0; lineIdx < root.commits.length; lineIdx++) {
                    var commitForLine = root.commits[lineIdx];
                    var posForLine = root.commitPositions[commitForLine.hash];
                    if (!posForLine) continue;

                    var centerYForLine = posForLine.y + root.commitItemHeight / 2 + root.commitItemSpacing;
                    if (centerYForLine + 12 < paintTop || centerYForLine - 12 > paintBottom)
                        continue;

                    var isHeadCommitForLabels = false;
                    var headBranchesForThisCommit = [];
                    for (var branchKey in branchLatestCommit) {
                        if (branchLatestCommit[branchKey] === commitForLine.hash) {
                            isHeadCommitForLabels = true;
                            headBranchesForThisCommit.push(branchKey);
                        }
                    }
                    if (!isHeadCommitForLabels && (!commitForLine.tagNames || commitForLine.tagNames.length === 0))
                        continue;

                    var centerXForLine = centerOffset + posForLine.column * root.columnSpacing + root.columnSpacing / 2;
                    var laneLabelColor = root.commitColor(commitForLine);

                    var allLabels = [];
                    if (commitForLine.tagNames && commitForLine.tagNames.length > 0) {
                        for (var tIdx = 0; tIdx < commitForLine.tagNames.length; tIdx++) {
                            allLabels.push({ text: commitForLine.tagNames[tIdx], color: "#e2c044", isTag: true });
                        }
                    }
                    for (var hbi = 0; hbi < headBranchesForThisCommit.length; hbi++) {
                        allLabels.push({ text: headBranchesForThisCommit[hbi], color: laneLabelColor, isTag: false });
                    }

                    if (allLabels.length > 0) {
                        var divider = root.graphColumnWidth + 10;
                        var nodeEnd = centerXForLine + 20;
                        var labelStartX = Math.max(divider, nodeEnd);
                        var labelY = centerYForLine;
                        var curX = labelStartX;
                        var labelSpacing = 8;

                        var labelPositions = [];
                        for (var calcIdx = 0; calcIdx < allLabels.length; calcIdx++) {
                            var lblInfo = allLabels[calcIdx];
                            ctx.font = "bold 11px sans-serif";
                            ctx.textAlign = "left";
                            var textW = ctx.measureText(lblInfo.text).width;
                            var extra = lblInfo.isTag ? 20 : 8;
                            var lblW = textW + 8 + extra;
                            labelPositions.push({ x: curX, width: lblW, info: lblInfo });
                            curX += lblW + labelSpacing;
                        }

                        if (labelPositions.length > 0) {
                            var lastLabel = labelPositions[labelPositions.length - 1];
                            var lineEndX = lastLabel.x + lastLabel.width;
                            ctx.save();
                            ctx.strokeStyle = laneLabelColor;
                            ctx.globalAlpha = 0.8;
                            ctx.lineWidth = 5;
                            ctx.beginPath();
                            ctx.moveTo(centerXForLine, centerYForLine);
                            ctx.lineTo(lineEndX, labelY);
                            ctx.stroke();
                            ctx.restore();
                        }

                        for (var drawIdx = 0; drawIdx < labelPositions.length; drawIdx++) {
                            var lblPos = labelPositions[drawIdx];
                            var lblInfo = lblPos.info;
                            var lx = lblPos.x;
                            var lw = lblPos.width;
                            var lh = 20;
                            var ly = labelY - lh / 2;

                            ctx.save();
                            ctx.fillStyle = lblInfo.color;
                            ctx.globalAlpha = 0.95;
                            GraphUtils.drawRoundedRect(ctx, lx, ly, lw, lh, 2);
                            ctx.fill();

                            var contrast = GraphUtils.getContrastColor(lblInfo.color);
                            ctx.fillStyle = contrast;
                            ctx.globalAlpha = 1.0;
                            ctx.textBaseline = "middle";
                            ctx.textAlign = "left";

                            if (lblInfo.isTag) {
                                ctx.font = "9px sans-serif";
                                ctx.fillText(typeof Style !== "undefined" ? Style.icons.tag : "🏷", lx + 4, labelY);
                                ctx.font = "bold 11px sans-serif";
                                ctx.fillText(lblInfo.text, lx + 20, labelY);
                            } else {
                                ctx.font = "bold 11px sans-serif";
                                ctx.fillText(lblInfo.text, lx + 8, labelY);
                            }
                            ctx.restore();
                        }
                    }
                }

                // Phase 4: Commit nodes
                for (var k = 0; k < root.commits.length; k++) {
                    var commit3 = root.commits[k];
                    var pos3 = root.commitPositions[commit3.hash];
                    if (!pos3) continue;
                    if (pos3.y + root.rowHeight < paintTop || pos3.y > paintBottom)
                        continue;

                    var centerX2 = centerOffset + pos3.column * root.columnSpacing + root.columnSpacing / 2;
                    var centerY2 = pos3.y + root.commitItemHeight / 2 + root.commitItemSpacing;
                    var branchColor3 = root.commitColor(commit3);

                    var isSelected = isCommitSelected(commit3.hash);
                    var isHead = commit3.hash === root.headHash;
                    var isHovered = (root.hoveredIndex >= 0 && k === root.hoveredIndex);
                    let isUncommitted = commit3.isUncommitted;

                    if (isSelected) {
                        ctx.fillStyle = "#6088B2DF";
                    } else if (isUncommitted && isHovered) {
                        ctx.fillStyle = Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.35);
                    } else if (isHovered) {
                        ctx.fillStyle = Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.15);
                    } else if (isUncommitted) {
                        ctx.fillStyle = Qt.rgba(Style.colors.accent.r, Style.colors.accent.g, Style.colors.accent.b, 0.22);
                    } else if (isHead) {
                        ctx.fillStyle = "#40FFA500";
                    }

                    if (isUncommitted || isSelected || isHovered || isHead)
                        ctx.fillRect(0, pos3.y, graphCanvas.width, root.commitItemHeight + root.commitItemSpacing*2);

                    ctx.save();
                    ctx.strokeStyle = isSelected ? GraphUtils.darkenColor(branchColor3, 0.2) : GraphUtils.lightenColor(branchColor3, 0.3);
                    ctx.lineWidth = isSelected ? 4 : 2.5;

                    var avatarSize = root.showAvatar ? root.commitItemHeight : 10;
                    var avatarRadius = avatarSize / 2;
                    var isStashNode = commit3.isStash === true;

                    if (isStashNode) {
                        var sqSize = avatarRadius;
                        ctx.beginPath();
                        ctx.moveTo(centerX2 - sqSize + 2, centerY2 - sqSize);
                        ctx.arcTo(centerX2 + sqSize, centerY2 - sqSize, centerX2 + sqSize, centerY2 + sqSize, 2);
                        ctx.arcTo(centerX2 + sqSize, centerY2 + sqSize, centerX2 - sqSize, centerY2 + sqSize, 2);
                        ctx.arcTo(centerX2 - sqSize, centerY2 + sqSize, centerX2 - sqSize, centerY2 - sqSize, 2);
                        ctx.arcTo(centerX2 - sqSize, centerY2 - sqSize, centerX2 + sqSize, centerY2 - sqSize, 2);
                        ctx.closePath();
                        ctx.fillStyle = branchColor3;
                        ctx.fill();
                        ctx.stroke();
                        if (root.showAvatar) {
                            ctx.fillStyle = "#ffffff";
                            ctx.textAlign = "center";
                            ctx.textBaseline = "middle";
                            ctx.fillText(typeof Style !== "undefined" ? Style.icons.archive : "📦", centerX2, centerY2);
                        }
                    } else {
                        ctx.beginPath();
                        ctx.arc(centerX2, centerY2, avatarRadius, 0, 2 * Math.PI);
                        ctx.fillStyle = root.showAvatar ? "#D9D9D9" : GraphUtils.lightenColor(branchColor3, 0.3);
                        ctx.fill();
                        ctx.stroke();
                        if (root.showAvatar) {
                            ctx.drawImage(graphCanvas.svgImage, centerX2 - graphCanvas.svgImage.width/2, centerY2 - graphCanvas.svgImage.height/2);
                        }
                    }
                    ctx.restore();
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/

    function commitColor(commitObj) {
        if (commitObj && commitObj.isUncommitted) return "#888888"
        if (!commitObj || !commitObj.colorKey) return GraphUtils.getCategoryColor("main")
        return GraphUtils.getCategoryColor(commitObj.colorKey)
    }

    function rebuildRenderCache() {
        var commitsHash = {}
        var commitByHash = {}
        var branchLatestCommit = {}
        var parentInSameLane = {}
        var crossLaneEdges = []

        for (var i = 0; i < root.commits.length; i++) {
            var commit = root.commits[i]
            if (!commit || !commit.hash)
                continue

            commitsHash[commit.hash] = true
            commitByHash[commit.hash] = commit

            if (commit.branchNames) {
                for (var branchIndex = 0; branchIndex < commit.branchNames.length; branchIndex++) {
                    var branchName = commit.branchNames[branchIndex]
                    if (branchName && !branchLatestCommit[branchName])
                        branchLatestCommit[branchName] = commit.hash
                }
            }
        }

        for (var commitIndex = 0; commitIndex < root.commits.length; commitIndex++) {
            var child = root.commits[commitIndex]
            if (!child || !child.parentHashes)
                continue

            var childPos = root.commitPositions[child.hash]
            if (!childPos)
                continue

            for (var parentIndex = 0; parentIndex < child.parentHashes.length; parentIndex++) {
                var parentHash = child.parentHashes[parentIndex]
                var parentPos = root.commitPositions[parentHash]
                if (!parentPos)
                    continue

                if (parentPos.column === childPos.column) {
                    if (!parentInSameLane[child.hash])
                        parentInSameLane[child.hash] = parentHash
                } else {
                    var isMerge = child.commitType === "merge"
                    crossLaneEdges.push({
                        from: isMerge ? parentHash : child.hash,
                        to: isMerge ? child.hash : parentHash,
                        fromPos: isMerge ? parentPos : childPos,
                        toPos: isMerge ? childPos : parentPos,
                        isMerge: isMerge
                    })
                }
            }
        }

        root.renderCache = {
            commitsHash: commitsHash,
            commitByHash: commitByHash,
            branchLatestCommit: branchLatestCommit,
            parentInSameLane: parentInSameLane,
            crossLaneEdges: crossLaneEdges
        }

        Qt.callLater(root.requestPaint)
    }

    function rowIndexAt(y) {
        var index = Math.floor(y / root.rowHeight)
        if (index < 0 || index >= root.commits.length)
            return -1

        var commit = root.commits[index]
        var pos = commit ? root.commitPositions[commit.hash] : null
        if (pos && y >= pos.y && y < pos.y + root.rowHeight)
            return index

        return -1
    }

    function requestPaint() {
        graphCanvas.invalidateAll()
    }

    onWidthChanged  :  graphCanvas.invalidateAll()
    onHeightChanged : graphCanvas.invalidateAll()
    onGraphContentHeightChanged: graphCanvas.invalidateAll()

    Component.onCompleted: rebuildRenderCache()
}
