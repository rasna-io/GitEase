import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * DiffView
 * ************************************************************************************************/

DetachablePanel {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var diffData: []   // used when chunkMode = false
    property var chunkData: []  // used when chunkMode = true

    /* Chunking configuration */
    property bool chunkMode     : false
    property int  contextLines  : 0         // how many unchanged lines to show around each hunk
    property int  expandLines   : 10        // lines to reveal when expanding a hidden block

    property bool readOnly: false

    property alias scrollPosition: diffListView.contentY

    /* Object Properties
     * ****************************************************************************************/
    title: qsTr("Diff View")

    /* Signals
     * ****************************************************************************************/
    signal requestStage(int start, int end, int type)
    signal requestRevert(int start, int end, int type)


    /* Children
     * ****************************************************************************************/
    ListModel {
        id: fileModel
    }

    ListModel {
        id: chunkModel
    }

    onDiffDataChanged: {
        if (chunkMode)
            return

        fileModel.clear()

        for(var i = 0; i < diffData.length; i++) {
            var diff = diffData[i];

            var left = diff.content;
            var right = (diff.type === GitDiff.Modified) ? diff.newContent : diff.content;

            // Visual "Gaps"
            if (diff.type === GitDiff.Added)
                left = "";
            if (diff.type === GitDiff.Deleted)
                right = "";

            appendRow(fileModel, diff.type, left, right, diff.oldLine, diff.newLine);

            updateMaxContentWidth(left);
            updateMaxContentWidth(right);
        }
    }

    onChunkDataChanged: {
        if (!chunkMode)
            return

        buildChunkModel()
    }

    TextMetrics {
        id: widthCalculator
        font.family: "Cascadia Mono"
        font.pixelSize: 13
    }

    EmptyStateView {
        title: "No file changes to show"
        details: "Select a file to view the Diff"
        visible: chunkMode ? (!chunkData || chunkData.length === 0)
                           : (!root.diffData || root.diffData.length === 0)
    }

    Rectangle {
        anchors.fill: parent
        color: Style.colors.editorBackgroound
        visible: chunkMode ? (chunkData && chunkData.length > 0)
                           : (root.diffData && root.diffData.length > 0)

        ListView {
            id: diffListView
            property real horizontalScrollOffset: 0
            property real maxContentWidth: 0

            anchors.fill: parent
            clip: true
            model: chunkMode ? chunkModel : fileModel

            cacheBuffer: 5000
            reuseItems: true
            anchors.bottomMargin: hScrollBar.visible ? hScrollBar.height : 0
            ScrollBar.vertical: ScrollBar { active: true }

            delegate: Item{
                id: delegateItem
                width: diffListView.width
                height: model.rowType === "hidden" ? 18 : diffLineItem.height

                MouseArea{
                    id: hiddenMarker
                    anchors.fill: parent
                    visible: model.rowType === "hidden"
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.expandHiddenBlock(index, model.direction)

                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        Text {
                            text: model.direction === "up" ? Style.icons.caretUp : Style.icons.caretDown
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: 13
                            color: hiddenMarker.containsMouse ? Style.colors.accent : Style.colors.secondaryText
                        }
                        Text {
                            text: model.hiddenCount - model.visibleCount
                            font.pixelSize: 10
                            color: hiddenMarker.containsMouse ? Style.colors.accent : Style.colors.secondaryText
                        }
                    }
                }

                SideBySideDiff {
                    id: diffLineItem
                    anchors.fill: parent
                    visible: model.rowType !== "hidden"
                    horizontalOffset: diffListView.horizontalScrollOffset
                    readOnly: root.readOnly || (root.chunkMode && model.rowType === "context")
                    diffModel: diffListView.model
                    diffType: (model.diffType !== undefined) ? model.diffType : GitDiff.Context
                    leftContent:  model.leftText  || ""
                    rightContent: model.rightText || ""
                    leftLineNum:  model.oldLineNum !== undefined ? model.oldLineNum : -1
                    rightLineNum: model.newLineNum !== undefined ? model.newLineNum : -1
                    isCurrentItem: ListView.isCurrentItem

                    onRequestSplit:  (pos, txt) => root.splitLine(index, pos, txt)
                    onRequestMergeUp: root.mergeLineUp(index)
                    onRequestFocusNext: diffListView.currentIndex = index + 1
                    onRequestFocusPrev: diffListView.currentIndex = index - 1
                    onRequestStage: (start, end, type) => root.requestStage(start, end, type)
                    onRequestRevert: (start, end, type) => root.requestRevert(start, end, type)
                }
            }
        }

        ScrollBar {
            id: hScrollBar
            orientation: Qt.Horizontal
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            size: diffListView.maxContentWidth === 0 ? 1 : (diffListView.width * 0.5) / diffListView.maxContentWidth
            active: true
            visible: size < 1.0

            onPositionChanged: {
                // Calculate the pixel offset based on scrollbar position
                diffListView.horizontalScrollOffset = position * diffListView.maxContentWidth
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function appendRow(model, type, lTxt, rTxt, lNum, rNum) {
        model.append({
                     "type": type,
                     "leftText": lTxt,
                     "rightText": rTxt,
                     "oldLineNum": lNum,
                     "newLineNum": rNum
                 })
    }

    // Called by Delegate when user presses Enter
    function splitLine(index, cursorPosition, textAfterCursor) {

        if (chunkMode)
            return

        // Update the current row to contain only text BEFORE cursor
        var currentRow = fileModel.get(index)
        var originalText = currentRow.rightText
        var textBefore = originalText.substring(0, cursorPosition)

        fileModel.setProperty(index, "rightText", textBefore)
        fileModel.setProperty(index, "type", GitDiff.Modified) // Mark as modified

        // Insert new row below with text AFTER cursor
        var newLineNum = currentRow.newLineNum + 1

        fileModel.insert(index + 1, {
                             "type": GitDiff.Added,
                             "leftText": "",
                             "rightText": textAfterCursor,
                             "oldLineNum": -1,
                             "newLineNum": newLineNum
                         })

        for (var i = index + 2; i < fileModel.count; i++) {
            var row = fileModel.get(i);
            if (row.newLineNum !== -1) {
                fileModel.setProperty(i, "newLineNum", row.newLineNum + 1);
            }
        }

        // Move focus to the new line (handled in Delegate via onAdded)
        diffListView.currentIndex = index + 1
    }

    // Called by Delegate when user presses Backspace at start
    function mergeLineUp(index) {
        if (index === 0) return;

        var currentRow = fileModel.get(index)
        var prevRow = fileModel.get(index - 1)

        // Don't merge if previous line is a "Delete" block (it has no right text box)
        if (prevRow.type === GitDiff.Deleted) return;

        var textToMove = currentRow.rightText
        var newCursorPos = prevRow.rightText.length

        // Append text to previous line
        fileModel.setProperty(index - 1, "rightText", prevRow.rightText + textToMove)

        // Remove current line
        fileModel.remove(index)

        // Move focus up
        diffListView.currentIndex = index - 1
        for (var i = index; i < fileModel.count; i++) {
            var row = fileModel.get(i);
            if (row.newLineNum !== -1) {
                fileModel.setProperty(i, "newLineNum", row.newLineNum - 1);
            }
        }
    }

    function updateMaxContentWidth(newText) {
        let visualText = newText.replace(/\t/g, "    ");

        widthCalculator.text = visualText;

        // Add a "safety buffer" so the cursor isn't flush against the edge
        var measuredWidth = widthCalculator.width + 200;

        if (measuredWidth > diffListView.maxContentWidth) {
            diffListView.maxContentWidth = measuredWidth;
        }
    }

    function buildChunkModel() {
        chunkModel.clear()

        if (!chunkData || chunkData.length === 0)
            return

        for (let c = 0; c < chunkData.length; c++) {
            let chunk = chunkData[c]

            if (chunk.chunkType === "changed") {
                let lines = chunk.lines
                for (let l = 0; l < lines.length; l++) {
                    let line    = lines[l]
                    let left    = (line.type === GitDiff.Added)     ? "" : line.content
                    let right   = (line.type === GitDiff.Deleted)   ? "" :
                                  (line.type === GitDiff.Modified   ? line.newContent : line.content)

                    chunkModel.append({
                        rowType     : "diff",
                        diffType    : line.type,
                        leftText    : left,
                        rightText   : right,
                        oldLineNum  : line.oldLine !== undefined ? line.oldLine : -1,
                        newLineNum  : line.newLine !== undefined ? line.newLine : -1
                    })
                    updateMaxContentWidth(left)
                    updateMaxContentWidth(right)
                }
            } else if (chunk.chunkType === "hidden") {
                let prevChunk = (c > 0) ? chunkData[c-1] : null
                let nextChunk = (c < chunkData.length-1) ? chunkData[c+1] : null

                if (prevChunk && prevChunk.chunkType === "changed") {
                    chunkModel.append({
                        rowType: "hidden",
                        direction: "down",
                        hiddenCount: chunk.hiddenCount,
                        visibleCount: 0,
                        chunkIndex: c
                    })
                }

                if (nextChunk && nextChunk.chunkType === "changed") {
                    chunkModel.append({
                        rowType: "hidden",
                        direction: "up",
                        hiddenCount: chunk.hiddenCount,
                        visibleCount: 0,
                        chunkIndex: c
                    })
                }
            }
        }
    }

    function expandHiddenBlock(modelIndex, direction) {
        let row = chunkModel.get(modelIndex)
        if (!row || row.rowType !== "hidden") 
            return

        let chunk = chunkData[row.chunkIndex]
        if (!chunk || chunk.chunkType !== "hidden" || !chunk.hiddenLines) 
            return

        let remaining = row.hiddenCount - row.visibleCount
        let toShow = Math.min(expandLines, remaining)
        if (toShow <= 0) return

        let hiddenLines = chunk.hiddenLines
        let newLines = []
        let oldVisible = row.visibleCount
        let oldBarIndex = modelIndex
        let chunkIdx = row.chunkIndex
        let totalHidden = row.hiddenCount

        // 1. Prepare the new context lines
        if (direction === "down") {
            for (let i = 0; i < toShow; i++) {
                let lineObj = hiddenLines[oldVisible + i]
                if (!lineObj) break
                newLines.push({
                    rowType: "context",
                    diffType: GitDiff.Context,
                    leftText: lineObj.content,
                    rightText: lineObj.content,
                    oldLineNum: lineObj.oldLine,
                    newLineNum: lineObj.newLine
                })
            }
        } else {  // "up"
            let endIdx = hiddenLines.length - 1 - oldVisible
            for (let i = 0; i < toShow; i++) {
                let idx = endIdx - i
                if (idx < 0) break
                let lineObj = hiddenLines[idx]
                newLines.push({
                    rowType: "context",
                    diffType: GitDiff.Context,
                    leftText: lineObj.content,
                    rightText: lineObj.content,
                    oldLineNum: lineObj.oldLine,
                    newLineNum: lineObj.newLine
                })
            }
            newLines.sort((a, b) => a.oldLineNum - b.oldLineNum)
        }

        // 2. Remove the bar temporarily
        chunkModel.remove(oldBarIndex)

        // 3. Insert the new lines at the bar's old position
        for (let i = 0; i < newLines.length; i++) {
            chunkModel.insert(oldBarIndex + i, newLines[i])
        }

        // 4. Re-insert the bar at the correct new position
        let newVisible = oldVisible + toShow
        let barProperties = {
            rowType: "hidden",
            direction: direction,
            hiddenCount: totalHidden,
            visibleCount: newVisible,
            chunkIndex: chunkIdx,
            diffType: GitDiff.Context,
            leftText: "", rightText: "",
            oldLineNum: -1, newLineNum: -1
        }

        if (direction === "down") {
            // Bar goes after the new lines
            chunkModel.insert(oldBarIndex + toShow, barProperties)
        } else {
            // Bar goes before the new lines (stay at oldBarIndex)
            chunkModel.insert(oldBarIndex, barProperties)
        }

        // 5. If fully expanded, remove this bar and its sibling
        if (newVisible >= totalHidden) {
            let barToRemove = direction === "down" ? oldBarIndex + toShow : oldBarIndex
            chunkModel.remove(barToRemove)
            for (let i = 0; i < chunkModel.count; i++) {
                let r = chunkModel.get(i)
                if (r.rowType === "hidden" && r.chunkIndex === chunkIdx) {
                    chunkModel.remove(i)
                    break
                }
            }
        }

        // 6. Update widths
        for (let line of newLines) {
            updateMaxContentWidth(line.leftText)
        }
    }

    function removeBarsForGap(anyBarIndex, chunkIdx) {
        // Remove the given bar first
        chunkModel.remove(anyBarIndex)
        // Then remove the other bar with the same chunkIndex
        for (let i = 0; i < chunkModel.count; i++) {
            let r = chunkModel.get(i)
            if (r.rowType === "hidden" && r.chunkIndex === chunkIdx) {
                chunkModel.remove(i)
                break
            }
        }
    }

    function appendHiddenBar(direction, chunk, chunkIdx) {
        chunkModel.append({
            rowType: "hidden",
            direction: direction,
            hiddenCount: chunk.hiddenCount || 0,
            visibleCount: 0,
            chunkIndex: chunkIdx,
            firstVisibleIndex: direction === "up" ? -1 : 0,   // used only for up
            diffType: GitDiff.Context,
            leftText: "", rightText: "",
            oldLineNum: -1, newLineNum: -1
        })
    }
}
