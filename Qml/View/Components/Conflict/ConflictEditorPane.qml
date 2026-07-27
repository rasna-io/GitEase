import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

import "qrc:/GitEase/Qml/Core/Scripts/ConflictPopupUtils.js" as ConflictUtils

/*! ***********************************************************************************************
 * ConflictEditorPane
 * Right-hand side of the conflict window: which file is open, and its rows.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property ListModel  displayModel        : null
    property string     selectedPath        : ""
    property var        selectedConflict    : null
    property alias      contentMetrics      : conflictListView
    property int        revision            : 0

    readonly property int openBlockCount: {
        root.revision
        return root.selectedConflict?.blocks?.length ?? 0
    }

    readonly property int firstOpenBlock: {
        root.revision
        return root.openBlockCount > 0 ? root.selectedConflict.blocks[0].index : -1
    }

    readonly property bool canNavigate: root.openBlockCount > 0
    readonly property bool canReset: root.selectedConflict !== null

    //! blockIndex -> { ours, theirs }, read off each block's own marker lines.
    readonly property var blockLabels: {
        root.revision
        let labels = ({})
        let blocks = root.selectedConflict?.blocks ?? []

        for (let block of blocks) {
            let ours   = "OURS"
            let theirs = "THEIRS"

            for (let line of (block.lines || [])) {
                if (line.role === "marker-start")
                    ours = `OURS (${line.text.replace("<<<<<<<", "").trim() || "HEAD"})`
                else if (line.role === "marker-end")
                    theirs = `THEIRS (${line.text.replace(">>>>>>>", "").trim()})`
            }

            labels[block.index] = { ours: `${Style.icons.caretRight} ${ours}`,
                                    theirs: `${Style.icons.caretRight} ${theirs}` }
        }

        return labels
    }

    /* Signals
     * ****************************************************************************************/
    signal acceptBlockRequested(int blockIndex, string mode)
    signal resetRequested()
    signal contentChanged()

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.editorBackgroound

    /* Functions
     * ****************************************************************************************/
    function openChunkRows() {
        let rows = []
        if (!root.displayModel)
            return rows

        for (let i = 0; i < root.displayModel.count; ++i) {
            let row = root.displayModel.get(i)
            if (row.type === "blockButton" && !(row.resolvedGroup > 0))
                rows.push(i)
        }
        return rows
    }

    function goToNextChunk() {
        let rows = root.openChunkRows()
        let next = rows.find(r => r > conflictListView.currentIndex)
        root.jumpTo(next !== undefined ? next : rows[0])
    }

    function goToPreviousChunk() {
        let rows = root.openChunkRows()
        let previous = rows.filter(r => r < conflictListView.currentIndex).pop()
        root.jumpTo(previous !== undefined ? previous : rows[rows.length - 1])
    }

    function jumpTo(rowIndex) {
        if (rowIndex === undefined)
            return

        conflictListView.currentIndex = rowIndex
        conflictListView.positionViewAtIndex(rowIndex, ListView.Beginning)
    }

    /*! Moves the caret to the first editable line of a block, so it can be resolved by hand. */
    function editBlock(blockIndex) {
        let range = ConflictUtils.findBlockRowRange(root.displayModel, blockIndex)
        if (range.start < 0)
            return

        for (let i = range.start; i <= range.end; ++i) {
            let role = root.displayModel.get(i).role
            if (role === "ours" || role === "theirs") {
                root.jumpTo(i)
                return
            }
        }

        root.jumpTo(range.start)
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // File bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(32)
            visible: root.selectedPath !== ""
            color: Style.colors.primaryBackground

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 8
                spacing: 8

                Text {
                    Layout.fillWidth: true
                    text: root.selectedPath
                    color: Style.colors.foreground
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.captionPt
                    elide: Text.ElideLeft
                }

                ConflictPillButton {
                    text: "Reset"
                    leadingText: Style.icons.undo
                    accentColor: Style.colors.mutedText
                    actionEnabled: root.canReset
                    tooltip: root.canReset
                             ? "Undo everything done to this file here, bringing back every conflict"
                             : "This file is already staged"
                    onClicked: root.resetRequested()
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            visible: root.selectedPath !== ""
            color: Style.colors.primaryBorder
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: conflictListView

                property real horizontalScrollOffset: 0
                property real maxContentWidth: 0

                anchors.fill: parent
                anchors.bottomMargin: hScrollBar.visible ? hScrollBar.height : 0
                clip: true
                model: root.displayModel

                cacheBuffer: 5000
                reuseItems: true

                ScrollBar.vertical: ScrollBar {
                    id: vScrollBar
                    active: true
                }

                // Minimap of the remaining conflict zones, drawn over the vertical scrollbar.
                Item {
                    id: conflictMarkerOverlay
                    parent: conflictListView
                    x: vScrollBar.x
                    y: vScrollBar.y
                    width: vScrollBar.width
                    height: vScrollBar.height
                    z: 100
                    clip: true

                    Repeater {
                        model: conflictMarkersModel

                        delegate: Rectangle {
                            required property real startRatio
                            required property real sizeRatio

                            x: 0
                            y: startRatio * conflictMarkerOverlay.height
                            width: conflictMarkerOverlay.width
                            height: Math.max(2, sizeRatio * conflictMarkerOverlay.height)
                            color: Style.colors.conflictMarker
                        }
                    }

                    onHeightChanged: {
                        if (height > 0)
                            markersUpdateTimer.restart()
                    }
                }

                delegate: ConflictEditorDelegate {
                    width: conflictListView.width
                    horizontalOffset: conflictListView.horizontalScrollOffset
                    isCurrentItem: ListView.isCurrentItem
                    blockLabels: root.blockLabels
                    openBlockCount: root.openBlockCount
                    firstOpenBlock: root.firstOpenBlock

                    onSplitRequested: (cursorPos) => {
                        ConflictUtils.splitLine(root.displayModel, index, cursorPos, conflictListView)
                        root.contentChanged()
                    }

                    onMergeUpRequested: {
                        ConflictUtils.mergeLineUp(root.displayModel, index, conflictListView)
                        root.contentChanged()
                    }

                    onAcceptBlockRequested: (blockIndex, mode) => root.acceptBlockRequested(blockIndex, mode)
                    onEditBlockRequested: (blockIndex) => root.editBlock(blockIndex)
                    onMoveFocusUp: conflictListView.currentIndex = Math.max(0, index - 1)
                    onMoveFocusDown: conflictListView.currentIndex =
                                     Math.min(root.displayModel.count - 1, index + 1)
                }
            }

            ScrollBar {
                id: hScrollBar
                orientation: Qt.Horizontal
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                active: true
                size: conflictListView.maxContentWidth === 0
                      ? 1 : (conflictListView.width * 0.5) / conflictListView.maxContentWidth
                visible: size < 1.0

                onPositionChanged: {
                    conflictListView.horizontalScrollOffset = position * conflictListView.maxContentWidth
                }
            }

            EmptyStateView {
                anchors.fill: parent
                visible: !root.displayModel || root.displayModel.count === 0
                title: "No conflicted files to show"
                details: "All conflicts have been resolved."
            }
        }
    }

    ListModel {
        id: conflictMarkersModel
    }

    Timer {
        id: markersUpdateTimer
        interval: 50
        onTriggered: root.updateConflictMarkers()
    }

    /* Marker minimap
     * ****************************************************************************************/
    function updateConflictMarkers() {
        conflictMarkersModel.clear()

        let totalRows = root.displayModel ? root.displayModel.count : 0
        if (totalRows === 0 || conflictMarkerOverlay.height <= 0)
            return

        let stack = []
        for (let i = 0; i < totalRows; ++i) {
            let row = root.displayModel.get(i)

            if (row.role === "marker-start") {
                stack.push(i)
            } else if (row.role === "marker-end" && stack.length > 0) {
                let startIdx = stack.pop()
                conflictMarkersModel.append({ startRatio: startIdx / totalRows,
                                              sizeRatio: (i - startIdx + 1) / totalRows })
            }
        }
    }

    function scheduleMarkerUpdate() {
        markersUpdateTimer.restart()
    }
}
