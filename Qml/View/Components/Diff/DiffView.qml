import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * DiffView
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var diffData: []

    property bool readOnly: false

    property int contextLines: -1  // -1 = show full file, 0 = changes only, N = changes + N lines context

    /* Signals
     * ****************************************************************************************/
    signal requestStage(int start, int end, int type)
    signal requestRevert(int start, int end, int type)


    /* Children
     * ****************************************************************************************/
    ListModel {
        id: fileModel
    }

    onDiffDataChanged: {
        rebuildModel();
    }

    onContextLinesChanged: {
        rebuildModel();
    }

    function rebuildModel() {
        fileModel.clear()

        if (contextLines === -1) {
            // Show full file
            for(var i = 0; i < diffData.length; i++) {
                var diff = diffData[i];
                addDiffLine(diff, -1, -1, -1);
            }
        } else {
            // Show changes in chunks with N context lines
            var chunks = buildChunks(diffData, contextLines);
            
            for(var c = 0; c < chunks.length; c++) {
                var chunk = chunks[c];
                
                if (c > 0) {
                    appendSeparator();
                }
                
                appendChunkHeader(chunk.start, chunk.end, c);
                
                for(var i = chunk.start; i <= chunk.end; i++) {
                    addDiffLine(diffData[i], chunk.start, chunk.end, c);
                }
            }
        }
    }

    function addDiffLine(diff, chunkStart, chunkEnd, chunkIndex) {
        var left = diff.content;
        var right = (diff.type === GitDiff.Modified) ? diff.newContent : diff.content;

        // Visual "Gaps"
        if (diff.type === GitDiff.Added)
            left = "";
        if (diff.type === GitDiff.Deleted)
            right = "";

        appendRow(diff.type, left, right, diff.oldLine, diff.newLine, chunkStart, chunkEnd, chunkIndex);

        updateMaxContentWidth(left);
        updateMaxContentWidth(right);
    }

    function buildChunks(data, context) {
        if (data.length === 0) return [];
        
        var chunks = [];
        var i = 0;
        
        while (i < data.length) {
            while (i < data.length && data[i].type === GitDiff.Context) {
                i++;
            }
            
            if (i >= data.length) break;
            
            var changeStart = i;
            var changeEnd = i;
            
            while (changeEnd < data.length && data[changeEnd].type !== GitDiff.Context) {
                changeEnd++;
            }
            changeEnd--;
            
            var chunkStart = Math.max(0, changeStart - context);
            var chunkEnd = Math.min(data.length - 1, changeEnd + context);
            if (chunks.length > 0) {
                var prevChunk = chunks[chunks.length - 1];
                if (chunkStart <= prevChunk.end + 1) {
                    prevChunk.end = chunkEnd;
                    i = chunkEnd + 1;
                    continue;
                }
            }
            
            chunks.push({start: chunkStart, end: chunkEnd});
            i = chunkEnd + 1;
        }
        
        return chunks;
    }

    function appendSeparator() {
        appendRow(-1, "...", "...", -1, -1, -1, -1, -1);
    }

    function appendChunkHeader(chunkStart, chunkEnd, chunkIndex) {
        appendRow(-2, "", "", -1, -1, chunkStart, chunkEnd, chunkIndex);
    }


    TextMetrics {
        id: widthCalculator
        font.family: "Cascadia Mono"
        font.pixelSize: 13
    }

    EmptyStateView {
        title: "No file changes to show"
        details: "Select a file to view the Diff"
        visible: !root.diffData || root.diffData.length === 0
    }

    Rectangle {
        anchors.fill: parent
        color: Style.colors.editorBackgroound
        visible: root.diffData && root.diffData.length > 0

        RowLayout {
            id: toolBar
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: 40
            spacing: 10
            z: 10

            Label {
                Layout.leftMargin: 10
                text: "Lines of context:"
                color: Style.colors.foreground
                font.pixelSize: 13
            }

            ComboBox {
                id: contextCombo
                Layout.preferredWidth: 120
                model: ["Full File", "0", "1", "2", "5", "10", "25"]
                currentIndex: 0
                minHeight: 26
                borderWidth: 0
                focusBorderWidth: 1
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 10

                Material.background: Style.colors.secondaryBackground
                Material.foreground: Style.colors.secondaryText
                
                onCurrentIndexChanged: {
                    if (currentIndex === 0) {
                        root.contextLines = -1;  // Full file
                    } else {
                        root.contextLines = parseInt(model[currentIndex]);
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }
        }

        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: toolBar.bottom
            height: 1
            color: Style.colors.surfaceMuted
        }

        ListView {
            id: diffListView
            property real horizontalScrollOffset: 0
            property real maxContentWidth: 0

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: toolBar.bottom
            anchors.topMargin: 1
            anchors.bottom: parent.bottom
            clip: true
            model: fileModel

            cacheBuffer: 1000
            reuseItems: true
            anchors.bottomMargin: hScrollBar.visible ? hScrollBar.height : 0
            ScrollBar.vertical: ScrollBar { active: true }

            delegate: SideBySideDiff {
                width: diffListView.width
                horizontalOffset: diffListView.horizontalScrollOffset
                readOnly: root.readOnly
                diffType: model.type
                leftContent: model.leftText
                rightContent: model.rightText
                leftLineNum: model.oldLineNum
                rightLineNum: model.newLineNum
                chunkStart: model.chunkStart
                chunkEnd: model.chunkEnd
                chunkIndex: model.chunkIndex
                fileModel: diffListView.model
                onRequestSplit: (pos, txt) => root.splitLine(index, pos, txt)
                onRequestMergeUp: root.mergeLineUp(index)
                onRequestFocusNext: diffListView.currentIndex = index + 1
                onRequestFocusPrev: diffListView.currentIndex = index - 1

                isCurrentItem: ListView.isCurrentItem

                onRequestStage: function (start, end, type) {
                    root.requestStage(start, end, type)
                }
                onRequestRevert: function (start, end, type) {
                    root.requestRevert(start, end, type)
                }
                onRequestStageChunk: function (chunkStart, chunkEnd) {
                    root.stageChunk(chunkStart, chunkEnd)
                }
                onRequestRevertChunk: function (chunkStart, chunkEnd) {
                    root.revertChunk(chunkStart, chunkEnd)
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
    function appendRow(type, lTxt, rTxt, lNum, rNum, chunkStart, chunkEnd, chunkIndex) {
        fileModel.append({
                             "type": type,
                             "leftText": lTxt,
                             "rightText": rTxt,
                             "oldLineNum": lNum,
                             "newLineNum": rNum,
                             "chunkStart": chunkStart !== undefined ? chunkStart : -1,
                             "chunkEnd": chunkEnd !== undefined ? chunkEnd : -1,
                             "chunkIndex": chunkIndex !== undefined ? chunkIndex : -1
                         })
    }

    // Called by Delegate when user presses Enter
    function splitLine(index, cursorPosition, textAfterCursor) {
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

    function stageChunk(chunkStart, chunkEnd) {
        var minOldLine = -1;
        var maxOldLine = -1;
        var minNewLine = -1;
        var maxNewLine = -1;
        var hasChanges = false;

        for (var i = 0; i < diffData.length; i++) {
            if (i >= chunkStart && i <= chunkEnd) {
                var diff = diffData[i];
                
                if (diff.type !== GitDiff.Context) {
                    hasChanges = true;
                    
                    if (diff.oldLine !== -1) {
                        if (minOldLine === -1 || diff.oldLine < minOldLine) {
                            minOldLine = diff.oldLine;
                        }
                        if (maxOldLine === -1 || diff.oldLine > maxOldLine) {
                            maxOldLine = diff.oldLine;
                        }
                    }
                    
                    if (diff.newLine !== -1) {
                        if (minNewLine === -1 || diff.newLine < minNewLine) {
                            minNewLine = diff.newLine;
                        }
                        if (maxNewLine === -1 || diff.newLine > maxNewLine) {
                            maxNewLine = diff.newLine;
                        }
                    }
                }
            }
        }

        if (!hasChanges) {
            console.log("No changes to stage in chunk");
            return;
        }

        var startLine = minOldLine !== -1 ? minOldLine : minNewLine;
        var endLine = maxOldLine !== -1 ? maxOldLine : maxNewLine;
        
        if (minOldLine === -1) {
            startLine = minNewLine;
            endLine = maxNewLine;
        } else if (minNewLine === -1) {
            startLine = minOldLine;
            endLine = maxOldLine;
        } else {
            startLine = Math.min(minOldLine, minNewLine);
            endLine = Math.max(maxOldLine, maxNewLine);
        }

        requestStage(startLine, endLine, GitDiff.Modified);
    }

    function revertChunk(chunkStart, chunkEnd) {
        var minOldLine = -1;
        var maxOldLine = -1;
        var minNewLine = -1;
        var maxNewLine = -1;
        var hasChanges = false;

        for (var i = 0; i < diffData.length; i++) {
            if (i >= chunkStart && i <= chunkEnd) {
                var diff = diffData[i];
                
                if (diff.type !== GitDiff.Context) {
                    hasChanges = true;
                    
                    if (diff.oldLine !== -1) {
                        if (minOldLine === -1 || diff.oldLine < minOldLine) {
                            minOldLine = diff.oldLine;
                        }
                        if (maxOldLine === -1 || diff.oldLine > maxOldLine) {
                            maxOldLine = diff.oldLine;
                        }
                    }
                    
                    if (diff.newLine !== -1) {
                        if (minNewLine === -1 || diff.newLine < minNewLine) {
                            minNewLine = diff.newLine;
                        }
                        if (maxNewLine === -1 || diff.newLine > maxNewLine) {
                            maxNewLine = diff.newLine;
                        }
                    }
                }
            }
        }

        if (!hasChanges) {
            console.log("No changes to revert in chunk");
            return;
        }

        var startLine = minOldLine !== -1 ? minOldLine : minNewLine;
        var endLine = maxOldLine !== -1 ? maxOldLine : maxNewLine;
        
        if (minOldLine === -1) {
            startLine = minNewLine;
            endLine = maxNewLine;
        } else if (minNewLine === -1) {
            startLine = minOldLine;
            endLine = maxOldLine;
        } else {
            startLine = Math.min(minOldLine, minNewLine);
            endLine = Math.max(maxOldLine, maxNewLine);
        }

        requestRevert(startLine, endLine, GitDiff.Modified);
    }

}
