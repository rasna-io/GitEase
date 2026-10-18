/*! ***********************************************************************************************
 * CommitGraphRouting Script
 * Converts commit lane positions into per-row drawing data, so every list row can render its own
 * slice of the graph (edges, node column and ref labels) without a shared canvas.
 *
 * Row descriptor:
 *   { column: int, edges: [Edge], refs: [Ref] }
 *   Edge: { path: SVG path relative to the row, color, opacity, dashed, dashOffset }
 *   Ref : { text: string, isTag: bool }
 * ************************************************************************************************/

.pragma library

/* Constants
 * ****************************************************************************************/
const EDGE_WIDTH          = 2.5
const MIN_CURVE_RADIUS    = 8

/* Public API
 * ****************************************************************************************/

/**
 * @param commits   ordered commit objects
 * @param positions hash -> { column, y } as produced by GraphLayout
 * @param metrics   { columnSpacing, itemHeight, itemSpacing }
 * @param palette   { commitColor(commit) }
 * @returns array of row descriptors, parallel to commits
 */
function buildRows(commits, positions, metrics, palette) {
    let rowHeight = metrics.itemHeight + metrics.itemSpacing * 2
    let rows = []
    for (let i = 0; i < commits.length; i++) {
        rows.push({ column: columnOf(commits[i], positions), edges: [], refs: [] })
    }

    let index = indexByHash(commits)
    let geometry = {
        rowHeight: rowHeight,
        columnSpacing: metrics.columnSpacing,
        itemHeight: metrics.itemHeight,
        centerOffset: metrics.itemHeight / 2 + metrics.itemSpacing,
        rowCount: commits.length
    }

    routeParentEdges(commits, positions, index, rows, geometry, palette)
    assignRefs(commits, rows)

    return rows
}

/* Edge routing
 * ****************************************************************************************/
function routeParentEdges(commits, positions, index, rows, geometry, palette) {
    for (let i = 0; i < commits.length; i++) {
        let child = commits[i]
        let childPos = positions[child.hash]
        if (!childPos)
            continue

        let parents = child.parentHashes || []
        let sameLaneDone = false
        let hasUnloadedParent = false

        for (let p = 0; p < parents.length; p++) {
            let parentRow = index[parents[p]]
            let parentPos = positions[parents[p]]

            if (parentRow === undefined) {
                hasUnloadedParent = true
                continue
            }
            if (!parentPos)
                continue

            if (parentPos.column === childPos.column) {
                if (!sameLaneDone) {
                    sameLaneDone = true
                    addStraightEdge(rows, geometry, childPos.column, i, parentRow,
                                    palette.commitColor(child), 0.9, child.isUncommitted === true)
                }
            } else {
                addCrossLaneEdge(rows, geometry, commits, i, childPos.column, parentRow, parentPos.column, palette)
            }
        }

        // A parent that is not loaded yet continues off-page: draw a dashed tail down to the last loaded row
        if (hasUnloadedParent) {
            addStraightEdge(rows, geometry, childPos.column, i, geometry.rowCount - 1,
                            palette.commitColor(child), 0.9, true, true)
        }
    }
}

function laneX(column, geometry) {
    return geometry.columnSpacing * (column + 1)
}

function addStraightEdge(rows, geometry, column, fromRow, toRow, color, opacity, dashed, toRowBottom) {
    let x = laneX(column, geometry)
    let startY = fromRow * geometry.rowHeight + geometry.centerOffset
    let endY = toRowBottom ? (toRow + 1) * geometry.rowHeight : toRow * geometry.rowHeight + geometry.centerOffset
    let lo = Math.min(fromRow, toRow)
    let hi = Math.max(fromRow, toRow)

    for (let r = lo; r <= hi; r++) {
        let top = r * geometry.rowHeight
        let y1 = Math.max(top, Math.min(startY, endY))
        let y2 = Math.min(top + geometry.rowHeight, Math.max(startY, endY))
        if (y2 <= y1)
            continue

        rows[r].edges.push({
            path: "M " + x + " " + (y1 - top) + " L " + x + " " + (y2 - top),
            color: color,
            opacity: opacity,
            dashed: dashed,
            dashOffset: dashed ? (y1 - Math.min(startY, endY)) / EDGE_WIDTH : 0
        })
    }
}

function addCrossLaneEdge(rows, geometry, commits, childRow, childColumn, parentRow, parentColumn, palette) {
    let child = commits[childRow]
    let isMerge = child.commitType === "merge"
    let childPoint = { x: laneX(childColumn, geometry), y: childRow * geometry.rowHeight + geometry.centerOffset }
    let parentPoint = { x: laneX(parentColumn, geometry), y: parentRow * geometry.rowHeight + geometry.centerOffset }

    let start = isMerge ? parentPoint : childPoint
    let end = isMerge ? childPoint : parentPoint
    let color = palette.commitColor(isMerge ? commits[parentRow] : child)
    let primitives = elbowPrimitives(start, end, geometry)

    let lo = Math.min(childRow, parentRow)
    let hi = Math.max(childRow, parentRow)
    for (let r = lo; r <= hi; r++) {
        let top = r * geometry.rowHeight
        let path = rowPath(primitives, top, top + geometry.rowHeight)
        if (path === "")
            continue

        rows[r].edges.push({ path: path, color: color, opacity: 0.85, dashed: false, dashOffset: 0 })
    }
}

/**
 * Breaks an elbow connector into lines and one quadratic corner.
 * Horizontal-first when moving right, vertical-first when moving left.
 */
function elbowPrimitives(start, end, geometry) {
    let deltaX = end.x - start.x
    let deltaY = end.y - start.y
    let radius = Math.min(Math.abs(deltaX) / 2, geometry.itemHeight, Math.abs(deltaY) / 2)
    radius = Math.max(radius, MIN_CURVE_RADIUS)
    let down = deltaY > 0

    if (deltaX === 0)
        return [line(start.x, start.y, end.x, end.y)]

    if (deltaX > 0) {
        let cornerY = down ? start.y + radius : start.y - radius
        return [
            line(start.x, start.y, end.x - radius, start.y),
            curve(end.x - radius, start.y, end.x, start.y, end.x, cornerY),
            line(end.x, cornerY, end.x, end.y)
        ]
    }

    let turnY = down ? end.y - radius : end.y + radius
    return [
        line(start.x, start.y, start.x, turnY),
        curve(start.x, turnY, start.x, end.y, start.x - radius, end.y),
        line(start.x - radius, end.y, end.x, end.y)
    ]
}

function line(x1, y1, x2, y2) {
    return { type: "L", x1: x1, y1: y1, x2: x2, y2: y2 }
}

function curve(x1, y1, cx, cy, x2, y2) {
    return { type: "Q", x1: x1, y1: y1, cx: cx, cy: cy, x2: x2, y2: y2 }
}

/** SVG path (relative to the row) of the primitives' portion inside [top, bottom], or "" if none. */
function rowPath(primitives, top, bottom) {
    let path = ""
    for (let i = 0; i < primitives.length; i++) {
        let primitive = primitives[i]
        if (primitive.type === "Q") {
            if (Math.max(primitive.y1, primitive.y2) < top || Math.min(primitive.y1, primitive.y2) > bottom)
                continue
            path += "M " + primitive.x1 + " " + (primitive.y1 - top)
                  + " Q " + primitive.cx + " " + (primitive.cy - top) + " " + primitive.x2 + " " + (primitive.y2 - top) + " "
            continue
        }

        let clipped = clipLine(primitive, top, bottom)
        if (clipped)
            path += "M " + clipped.x1 + " " + (clipped.y1 - top) + " L " + clipped.x2 + " " + (clipped.y2 - top) + " "
    }
    return path
}

function clipLine(segment, top, bottom) {
    if (segment.y1 === segment.y2) {
        return segment.y1 >= top && segment.y1 <= bottom ? segment : null
    }

    let y1 = Math.max(top, Math.min(segment.y1, segment.y2))
    let y2 = Math.min(bottom, Math.max(segment.y1, segment.y2))
    if (y2 <= y1)
        return null

    let ascending = segment.y2 > segment.y1
    return { x1: segment.x1, y1: ascending ? y1 : y2, x2: segment.x2, y2: ascending ? y2 : y1 }
}

/* Ref labels
 * ****************************************************************************************/

/** Tags sit on their commit; a branch label sits on the first (newest) commit listing that branch. */
function assignRefs(commits, rows) {
    let seenBranches = {}
    for (let i = 0; i < commits.length; i++) {
        let commit = commits[i]
        let refs = rows[i].refs

        let tags = commit.tagNames || []
        for (let t = 0; t < tags.length; t++) {
            refs.push({ text: tags[t], isTag: true })
        }

        let branches = commit.branchNames || []
        for (let b = 0; b < branches.length; b++) {
            if (branches[b] && !seenBranches[branches[b]]) {
                seenBranches[branches[b]] = true
                refs.push({ text: branches[b], isTag: false })
            }
        }
    }
}

/* Helpers
 * ****************************************************************************************/
function columnOf(commit, positions) {
    let position = commit ? positions[commit.hash] : null
    return position ? position.column : 0
}

function indexByHash(commits) {
    let index = {}
    for (let i = 0; i < commits.length; i++) {
        index[commits[i].hash] = i
    }
    return index
}
