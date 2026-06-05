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
    property int currentIndex: -1

    // Properties used for selection
    property bool selectEnabled: true // used to disable mouse area so that it does not block editing file
    property int selectionStart: -1
    property int selectionEnd: -1
    property int selectedSide: Enums.DiffViewSelectionSide.None
    property bool dragging: false

    property alias scrollPosition: diffListView.contentY

    /* Object Properties
     * ****************************************************************************************/
    title: qsTr("Diff View")

    /* Signals
     * ****************************************************************************************/
    signal requestStage(int start, int end, int type, var rows)
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

        selectionStart = -1
        selectionEnd = -1
    }

    onChunkDataChanged: {
        if (!chunkMode)
            return

        buildChunkModel()

        selectionStart = -1
        selectionEnd = -1
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
            ScrollBar.vertical: ScrollBar {
                id: vScrollBar
                active: true
            }

            TextEdit {
                id: clipboardHelper
                visible: false
            }

            MouseArea {
                id: selectMsa
                height: parent.height
                width: parent.width - (vScrollBar.visible ? vScrollBar.width : 0)
                propagateComposedEvents: true
                z: 1
                focus: true
                Keys.enabled: true
                enabled: root.selectEnabled
                visible: root.selectEnabled

                onPressed: (mouse) => {
                   diffListView.interactive = false // Disable flicking during selection
                   var item = diffListView.itemAt(mouse.x, mouse.y + diffListView.contentY)
                   var idx = diffListView.indexAt(mouse.x, mouse.y + diffListView.contentY)
                   var row = diffListView.model.get(idx)

                   if(idx < 0) return
                   if(row.rowType === "hidden")
                       return

                    forceActiveFocus()

                    root.dragging = true

                   if (!(mouse.modifiers & Qt.ShiftModifier)) {
                       root.selectionStart = idx
                       root.selectionEnd = idx
                   } else {
                       root.selectionEnd = idx
                   }

                    // Checks which side of diffview is selected
                    selectedSide = mouse.x < selectMsa.width / 2 ? Enums.DiffViewSelectionSide.Left : Enums.DiffViewSelectionSide.Right
                }

                onPositionChanged: (mouse) => {
                    if (!root.dragging) return

                   var margin = 40

                   var maxScroll = Math.max(
                       0,
                       diffListView.contentHeight - diffListView.height
                   )

                   // Scroll up
                   if (mouse.y < margin && maxScroll > 0) {
                       diffListView.contentY = Math.max(
                           0,
                           diffListView.contentY - 10
                       )
                   }

                   // Scroll down
                   if (mouse.y > height - margin && maxScroll > 0) {
                       diffListView.contentY = Math.min(
                           maxScroll,
                           diffListView.contentY + 10
                       )
                   }

                   var idx = diffListView.indexAt(mouse.x, mouse.y + diffListView.contentY)
                   var row = diffListView.model.get(idx)

                    if (idx >= 0)
                    {
                        if(row.rowType === "hidden")
                            return
                        root.selectionEnd = idx
                    }
                }

                onReleased: {
                    diffListView.interactive = true
                    root.dragging = false
                }

                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_A &&
                        (event.modifiers & Qt.ControlModifier))
                    {
                        var first = -1
                        var last = -1

                        for (var i = 0; i < diffListView.model.count; ++i) {
                            var row = diffListView.model.get(i)

                            if (row.rowType === "hidden")
                                continue

                            if (first === -1)
                                first = i

                            last = i
                        }

                        if (first !== -1) {
                            root.selectionStart = first
                            root.selectionEnd = last
                        }

                        event.accepted = true
                        return
                    }

                    if (event.key === Qt.Key_C &&
                        (event.modifiers & Qt.ControlModifier))
                    {
                        var min = Math.min(root.selectionStart, root.selectionEnd)
                        var max = Math.max(root.selectionStart, root.selectionEnd)

                        var copied = ""

                        for (var i = min; i <= max; i++) {
                            var row = diffListView.model.get(i)

                            if (!row || row.rowType === "hidden")
                                continue

                            var text = ""
                            if(root.selectedSide === Enums.DiffViewSelectionSide.Left)
                                text += row.leftText
                            else if(root.selectedSide === Enums.DiffViewSelectionSide.Right)
                                text += row.rightText

                            copied += text + "\n"
                        }

                        clipboardHelper.text = copied
                        clipboardHelper.selectAll()
                        clipboardHelper.copy()

                        event.accepted = true
                        return
                    }
                }
            }

            delegate: Item{
                id: delegateItem
                width: diffListView.width
                implicitHeight: model.rowType === "hidden" ? 45 : diffLineItem.implicitHeight

                Loader {
                    id: loader
                    anchors.fill: parent
                    active: root.chunkMode && diffListView.model.count > 0 && model.rowType === "hidden"
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
                    readOnly: root.readOnly
                    diffModel: diffListView.model
                    diffType: (model.diffType !== undefined) ? model.diffType : GitDiff.Context
                    leftContent:  model.leftText  || ""
                    rightContent: model.rightText || ""
                    leftLineNum:  model.oldLineNum !== undefined ? model.oldLineNum : -1
                    rightLineNum: model.newLineNum !== undefined ? model.newLineNum : -1
                    isCurrentItem: index === root.currentIndex
                    selectionStart: root.selectionStart
                    selectionEnd: root.selectionEnd
                    selectedSide: root.selectedSide
                    hasAction: checkHasAction(diffListView.model, index, diffType)

                    onRequestTextChange: (newText) => root.changeText(index, newText)
                    onRequestSplit:  (pos, txt) => root.splitLine(index, pos, txt)
                    onRequestMergeUp: root.mergeLineUp(index)
                    onRequestFocusNext: diffListView.currentIndex = index + 1
                    onRequestFocusPrev: diffListView.currentIndex = index - 1
                    onRequestStage: (start, end, type) => root.requestStage(start, end, type, getFileRows(diffListView.model))
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
                     "diffType": type,
                     "leftText": lTxt,
                     "rightText": rTxt,
                     "oldLineNum": lNum,
                     "newLineNum": rNum
                 })
    }

    function updateRowState(model, index)
    {
        let row = model.get(index)

        let modified = row.leftText !== row.rightText

        model.setProperty(index, "diffType", modified ? GitDiff.Modified : GitDiff.Context)

        if (chunkMode)
            model.setProperty(index, "rowType", modified ? "diff" : "unchanged")
    }

    function checkHasAction(model, index, type) {
        if (readOnly || type === GitDiff.Context)
            return false;
        if (index === 0)
            return true;

        if (!model || !model.get)
            return false;

        let prevItem = model.get(index - 1);
        if (!prevItem)
            return false;

        return prevItem.rowType !== "diff";
    }

    // Called when user interacts with the textEdit
    function changeText(index, newText)
    {
        let model = chunkMode ? chunkModel : fileModel
        let row = model.get(index)
        if (!row)
            return

        // Set the newText as the currentText of the textEdit
        model.setProperty(index, "rightText", newText)

        // Dont update the row state to modified if it is an added line
        if (row.diffType === GitDiff.Added)
            return

        updateRowState(model, index)

        for (var i = 0; i < model.count; i++) {
            row = model.get(i);
            if (true) {
                model.setProperty(i, "hasAction", checkHasAction(model, i, row.diffType))
            }
        }
    }

    // Called by Delegate when user presses Enter
    function splitLine(index, cursorPosition, textAfterCursor) {
        let model = chunkMode ? chunkModel : fileModel

        // Update the current row to contain only text BEFORE cursor
        var currentRow = model.get(index)
        var originalText = currentRow.rightText
        var textBefore = originalText.substring(0, cursorPosition)

        model.setProperty(index, "rightText", textBefore)
        if(currentRow.diffType !== GitDiff.Added)
            updateRowState(model, index)

        var newLineNum = currentRow.newLineNum + 1
        let nextRow = model.get(index + 1)

        // If nextRow is Deleted update its state, otherwise add a new row
        if(nextRow && nextRow.diffType === GitDiff.Deleted)
        {
            model.setProperty(index + 1, "rightText", textAfterCursor)
            updateRowState(model, index + 1)
        }
        else {
            if(chunkModel) {
                model.insert(index + 1, {
                    rowType     : "diff",
                    diffType    : GitDiff.Added,
                    leftText    : "",
                    rightText   : textAfterCursor,
                    oldLineNum  : -1,
                    newLineNum  : newLineNum
                })
            } else {
                model.insert(index + 1, {
                     "diffType": GitDiff.Added,
                     "leftText": "",
                     "rightText": textAfterCursor,
                     "oldLineNum": -1,
                     "newLineNum": newLineNum
                })
            }
        }

        // Move focus to the new line (handled in Delegate via onAdded)
        root.currentIndex = index + 1

        for (var i = index + 2; i < model.count; i++) {
            var row = model.get(i);
            if (row.newLineNum !== -1) {
                model.setProperty(i, "newLineNum", row.newLineNum + 1);
            }
        }
    }

    // Called by Delegate when user presses Backspace at start
    function mergeLineUp(index)
    {
        let model = chunkMode ? chunkModel : fileModel

        if (index === 0)
            return

        let currentRow = model.get(index)
        let prevRow = model.get(index - 1)

        if (!currentRow || !prevRow)
            return

        if (prevRow.diffType === GitDiff.Deleted)
            return

        let newRightText = prevRow.rightText + currentRow.rightText
        model.setProperty(index - 1, "rightText", newRightText)

        // Remove added lines, otherwise mark as deleted while preserving diff history.
        if (currentRow.diffType === GitDiff.Added)
        {
            model.remove(index)

            for (let i = index ; i < model.count; i++)
            {
                let row = model.get(i)
                if (row.newLineNum !== -1)
                    model.setProperty(i, "newLineNum", row.newLineNum - 1)
            }
        }
        else
        {
            model.setProperty(index, "diffType", GitDiff.Deleted)

            if (chunkMode)
                model.setProperty(index, "rowType", "diff")

            updateRowState(model, index - 1)

            for (let i = index + 1; i < model.count; i++)
            {
                let row = model.get(i)
                if (row.newLineNum !== -1)
                    model.setProperty(i, "newLineNum", row.newLineNum - 1)
            }
        }

        // Move focus up
        root.currentIndex = index - 1
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

    // Returns the lines of the rightTextEdit currentText used for saving the file
    function getFileRows(model) {
        let rows = []

        if (chunkMode) {
            let i = 0

            // keep expanding until no hidden rows exist
            while (i < model.count) {
                let row = model.get(i)

                if (row && row.rowType === "hidden") {
                    expandHiddenBlock(i, row.direction, Infinity)
                    i = 0 // restart scan because model changed
                    continue
                }

                i++
            }
        }

        for (let i = 0; i < model.count; i++) {
            let row = model.get(i)
            if (row)
                rows.push(row.rightText || "")
        }

        return rows
    }
}
