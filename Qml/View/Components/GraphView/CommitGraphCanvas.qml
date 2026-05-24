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

    /* Signals
     * ****************************************************************************************/
    signal infiniteScroll()

    /* Children
     * ****************************************************************************************/
    Flickable {
        id: flick
        anchors.fill: parent
        clip: true

        contentWidth: {
            if (!commits.length) return width
            var maxCols = 0
            for (var i = 0; i < commits.length; i++) {
                var hash = commits[i].hash
                var pos = commitPositions[hash]
                if (pos && pos.column > maxCols) maxCols = pos.column
            }
            return Math.max(width, 40 + (maxCols+1) * columnSpacing + 300)
        }
        contentHeight: Math.max(height, commits.length * (commitItemHeight + commitItemSpacing*2))
        boundsBehavior: Flickable.StopAtBounds

        property bool syncScroll: false

        onContentYChanged: {
            if (flick.contentHeight > flick.height) {
                var remaining = flick.contentHeight - (flick.contentY + flick.height)
                if (remaining < 300) root.infiniteScroll()
            }
        }

        // ---------- Canvas (draws the entire DAG) ----------
        Canvas {
            id: graphCanvas
            width: flick.contentWidth
            height: commits.length * (commitItemHeight + commitItemSpacing*2)

            property var svgImage: Image {
                source: "qrc:/GitEase/Resources/Images/defaultUserIcon.svg"
                anchors.centerIn: parent
                height: 14.5; width: 14.5
            }

            // Trigger repaint when data changes
            Connections {
                target: root
                function onCommitsChanged() { graphCanvas.requestPaint() }
                function onSelectedHashesChanged() { graphCanvas.requestPaint() }
            }

            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                if (!root.commits || root.commits.length === 0) return;

                // Also handles continuation lines: when a node is not present in the viewport,
                // a straight line is rendered to preserve visual continuity in the graph.
                let commitsHash = []
                var maxCols = 0;
                for (var i = 0; i < root.commits.length; i++) {
                    let hash = root.commits[i].hash
                    commitsHash.push(hash)
                    var p = root.commitPositions[hash];
                    if (p && p.column > maxCols) maxCols = p.column;
                }

                // ---- Start of original drawing logic (adapted) ----

                var centerOffset = root.columnSpacing / 2;

                // Build quick lookup
                var commitByHash = {};
                for (var bi0 = 0; bi0 < root.commits.length; bi0++) {
                    var c0m = root.commits[bi0];
                    if (c0m && c0m.hash) commitByHash[c0m.hash] = c0m;
                }

                // Branch HEAD mapping
                var branchLatestCommit = {};
                for (var bi = 0; bi < root.commits.length; bi++) {
                    var bc = root.commits[bi];
                    if (bc && bc.branchNames && bc.branchNames.length) {
                        for (var bni = 0; bni < bc.branchNames.length; bni++) {
                            var bn = bc.branchNames[bni];
                            if (bn && !branchLatestCommit[bn]) branchLatestCommit[bn] = bc.hash;
                        }
                    }
                }

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
                var parentInSameLane = {};
                var crossLaneEdges = [];
                for (var j = 0; j < root.commits.length; j++) {
                    var c0 = root.commits[j];
                    var pos0 = root.commitPositions[c0.hash];
                    if (!pos0 || !c0.parentHashes) continue;
                    for (var p2 = 0; p2 < c0.parentHashes.length; p2++) {
                        var parentHash = c0.parentHashes[p2];
                        var parentPos = root.commitPositions[parentHash];
                        if (!parentPos) continue;
                        if (parentPos.column === pos0.column) {
                            if (!parentInSameLane[c0.hash]) parentInSameLane[c0.hash] = parentHash;
                        } else {
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
                    } else {
                        // Check if any parent is outside loaded set
                        var canDraw = false;
                        for (var i2 = 0; i2 < commit2.parentHashes.length; i2++) {
                            if (commitsHash.indexOf(commit2.parentHashes[i2]) === -1) {
                                canDraw = true;
                                break;
                            }
                        }
                        if (canDraw) {
                            var branchColor2 = root.commitColor(commit2);
                            ctx.save();
                            ctx.strokeStyle = branchColor2;
                            ctx.globalAlpha = 0.9;
                            ctx.lineWidth = 2.5;
                            ctx.beginPath();
                            ctx.moveTo(centerX, centerY);
                            ctx.lineTo(centerX, graphCanvas.height);
                            ctx.stroke();
                            ctx.restore();
                        }
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
                    var centerYForLine = posForLine.y + root.commitItemHeight / 2 + root.commitItemSpacing;
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

                    var centerX2 = centerOffset + pos3.column * root.columnSpacing + root.columnSpacing / 2;
                    var centerY2 = pos3.y + root.commitItemHeight / 2 + root.commitItemSpacing;
                    var branchColor3 = root.commitColor(commit3);

                    var isSelected = isCommitSelected(commit3.hash);
                    var isHead = commit3.hash === root.headHash;

                    if (isSelected) {
                        ctx.fillStyle = "#6088B2DF";
                        ctx.fillRect(0, pos3.y, graphCanvas.width, root.commitItemHeight + root.commitItemSpacing*2);
                    } else if (isHead) {
                        ctx.fillStyle = "#40FFA500";
                        ctx.fillRect(0, pos3.y, graphCanvas.width, root.commitItemHeight + root.commitItemSpacing*2);
                    }

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

    onWidthChanged  :  graphCanvas.requestPaint()
    onHeightChanged : graphCanvas.requestPaint()
}
