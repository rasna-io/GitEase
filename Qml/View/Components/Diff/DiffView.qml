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
    property var  textColorizer: null   // JS function (text) => richHtml, set by host

    property alias scrollPosition: diffListView.contentY

    /* Object Properties
     * ****************************************************************************************/
    title: qsTr("Diff View")

    /* Signals
     * ****************************************************************************************/
    signal requestStage(int start, int end, int type)
    signal requestRevert(int start, int end, int type)
    signal requestStash(int start, int end, int type)

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

            cacheBuffer: 0
            reuseItems: false
            anchors.bottomMargin: hScrollBar.visible ? hScrollBar.height : 0
            ScrollBar.vertical: ScrollBar { active: true }

            delegate: Item{
                id: delegateItem
                width: diffListView.width
                height: model.rowType === "hidden" ? 24 : diffLineItem.height

                Loader {
                    anchors.fill: parent
                    active: root.chunkMode && model.rowType === "hidden"
                    sourceComponent: hiddenBarComponent

                    onLoaded: {
                        if (!item)
                            return

                        item.direction      = Qt.binding(function() { return model.direction })
                        item.remaining      = Qt.binding(function() { return model.remaining })
                        item.delegateIndex  = Qt.binding(function() { return index })
                    }
                }

                SideBySideDiff {
                    id: diffLineItem
                    anchors.fill: parent
                    visible: model.rowType !== "hidden"
                    horizontalOffset: diffListView.horizontalScrollOffset
                    textColorizer: root.textColorizer
                    readOnly: root.readOnly || (root.chunkMode && model.rowType === "context")
                    diffModel: diffListView.model
                    diffType: (model.diffType !== undefined) ? model.diffType
                             : (model.type !== undefined) ? model.type
                             : GitDiff.Context
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
                    onRequestStash: (start, end, type) => root.requestStash(start, end, type)
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

    Component {
        id: hiddenBarComponent
        Item {
            property string direction: ""
            property int remaining: 0
            property int delegateIndex: -1

            anchors.fill: parent

            MouseArea {
                id: hiddenMarker
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.expandHiddenBlock(delegateIndex, direction)
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                height: 1
                color: hiddenMarker.containsMouse ? Style.colors.accent : Style.colors.primaryBorder
            }

            Row {
                anchors.centerIn: parent
                spacing: 6
                Label {
                    text: direction === "up" ? Style.icons.arrowUpToLine : Style.icons.arrowDownToLine
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: 12
                    color: hiddenMarker.containsMouse ? Style.colors.secondaryForeground : Style.colors.secondaryText
                    padding: 4
                    background: Rectangle {
                        color: hiddenMarker.containsMouse ? Style.colors.accent
                                                          : Qt.darker(Style.colors.linePanelBackgroound, 1.05)
                        radius: 4
                    }
                }
                Label {
                    text: remaining
                    font.family: Style.fontTypes.roboto
                    font.pixelSize: 9
                    color: hiddenMarker.containsMouse ? Style.colors.secondaryForeground : Style.colors.secondaryText
                    padding: 3
                    background: Rectangle {
                        color: hiddenMarker.containsMouse ? Style.colors.accent
                                                          : Qt.darker(Style.colors.linePanelBackgroound, 1.05)
                        radius: 3
                    }
                }
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
        if (chunkMode)
            return

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
                chunk.visibleTop = 0
                chunk.visibleBottom = 0

                let prevChunk = (c > 0) ? chunkData[c-1] : null
                let nextChunk = (c < chunkData.length-1) ? chunkData[c+1] : null

                if (prevChunk && prevChunk.chunkType === "changed") {
                    chunkModel.append({
                        rowType: "hidden",
                        direction: "down",
                        hiddenCount: chunk.hiddenCount,
                        remaining: chunk.hiddenCount,
                        chunkIndex: c
                    })
                }

                if (nextChunk && nextChunk.chunkType === "changed") {
                    chunkModel.append({
                        rowType: "hidden",
                        direction: "up",
                        hiddenCount: chunk.hiddenCount,
                        remaining: chunk.hiddenCount,
                        chunkIndex: c
                    })
                }
            }
        }
        if (root.contextLines > 0) {
            let processedChunks = []
            for (let c = 0; c < chunkData.length; c++) {
                let chunk = chunkData[c]
                if (chunk.chunkType !== "hidden")
                    continue

                let downIdx = -1, upIdx = -1
                for (let i = 0; i < chunkModel.count; i++) {
                    let r = chunkModel.get(i)
                    if (r.rowType === "hidden" && r.chunkIndex === c) {
                        if (r.direction === "down") downIdx = i
                        else if (r.direction === "up") upIdx = i
                    }
                }
                if (downIdx !== -1) {
                    root.expandHiddenBlock(downIdx, "down", root.contextLines)
                    if (upIdx !== -1) {
                        upIdx = -1
                        for (let j = 0; j < chunkModel.count; j++) {
                            let r = chunkModel.get(j)
                            if (r.rowType === "hidden" && r.chunkIndex === c && r.direction === "up")
                                upIdx = j
                        }
                    }
                }
                if (upIdx !== -1) {
                    root.expandHiddenBlock(upIdx, "up", root.contextLines)
                }
            }
        }
    }

    function expandHiddenBlock(modelIndex, direction, customCount) {
        let bar = chunkModel.get(modelIndex)
        if (!bar || bar.rowType !== "hidden")
            return

        let chunk = chunkData[bar.chunkIndex]
        if (!chunk || chunk.chunkType !== "hidden" || !chunk.hiddenLines)
            return

        let totalHidden = chunk.hiddenCount
        let visibleTop = chunk.visibleTop || 0
        let visibleBottom = chunk.visibleBottom || 0
        let remaining = totalHidden - visibleTop - visibleBottom
        if (remaining <= 0)
            return

        let toShow = Math.min(customCount !== undefined ? customCount : root.expandLines, remaining)
        if (toShow <= 0)
            return

        let hiddenLines = chunk.hiddenLines
        let newLines = []
        let oldBarIndex = modelIndex
        let chunkIdx = bar.chunkIndex

        if (direction === "down") {
            for (let i = 0; i < toShow; i++) {
                let lineObj = hiddenLines[visibleTop + i]
                if (!lineObj) break
                newLines.push(makeContextLine(lineObj))
            }

            chunkModel.remove(oldBarIndex)
            for (let i = 0; i < newLines.length; i++)
                chunkModel.insert(oldBarIndex + i, newLines[i])

            chunk.visibleTop = visibleTop + toShow

            let newRemaining = totalHidden - chunk.visibleTop - chunk.visibleBottom
            chunkModel.insert(oldBarIndex + toShow, {
                rowType: "hidden",
                direction: "down",
                hiddenCount: totalHidden,
                remaining: newRemaining,
                chunkIndex: chunkIdx
            })

        } else { // "up"
            let endIdx = hiddenLines.length - 1 - visibleBottom
            for (let i = 0; i < toShow; i++) {
                let idx = endIdx - i
                if (idx < 0) break
                newLines.push(makeContextLine(hiddenLines[idx]))
            }
            newLines.sort((a, b) => a.oldLineNum - b.oldLineNum)

            chunkModel.remove(oldBarIndex)
            for (let i = 0; i < newLines.length; i++)
                chunkModel.insert(oldBarIndex + i, newLines[i])

            chunk.visibleBottom = visibleBottom + toShow

            let newRemaining = totalHidden - chunk.visibleTop - chunk.visibleBottom
            chunkModel.insert(oldBarIndex, {
                rowType: "hidden",
                direction: "up",
                hiddenCount: totalHidden,
                remaining: newRemaining,
                chunkIndex: chunkIdx
            })
        }

        let finalRemaining = totalHidden - chunk.visibleTop - chunk.visibleBottom
        for (let i = 0; i < chunkModel.count; i++) {
            let r = chunkModel.get(i)
            if (r.rowType === "hidden" && r.chunkIndex === chunkIdx) {
                chunkModel.setProperty(i, "remaining", finalRemaining)
            }
        }

        if (finalRemaining <= 0) {
            for (let i = chunkModel.count - 1; i >= 0; i--) {
                let r = chunkModel.get(i)
                if (r.rowType === "hidden" && r.chunkIndex === chunkIdx)
                    chunkModel.remove(i)
            }
        }

        for (let line of newLines)
            updateMaxContentWidth(line.leftText)
    }

    function makeContextLine(lineObj) {
        return {
            rowType: "context",
            diffType: GitDiff.Context,
            leftText: lineObj.content,
            rightText: lineObj.content,
            oldLineNum: lineObj.oldLine,
            newLineNum: lineObj.newLine
        }
    }
}
