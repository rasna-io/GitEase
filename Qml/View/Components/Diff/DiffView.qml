import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * DiffView
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var diffData: []

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

            appendRow(diff.type, left, right, diff.oldLine, diff.newLine);

            updateMaxContentWidth(left);
            updateMaxContentWidth(right);
        }
    }


    TextMetrics {
        id: widthCalculator
        font.family: "Cascadia Mono"
        font.pixelSize: 13
    }

    Rectangle {
        anchors.fill: parent
        color: Style.colors.editorBackgroound

        ListView {
            id: diffListView
            property real horizontalScrollOffset: 0
            property real maxContentWidth: 0

            anchors.fill: parent
            clip: true
            model: fileModel

            cacheBuffer: 1000
            reuseItems: true
            anchors.bottomMargin: hScrollBar.visible ? hScrollBar.height : 0
            ScrollBar.vertical: ScrollBar { active: true }

            delegate: SideBySideDiff {
                width: diffListView.width
                horizontalOffset: diffListView.horizontalScrollOffset
                // Pass properties
                diffType: model.type
                leftContent: model.leftText
                rightContent: model.rightText
                leftLineNum: model.oldLineNum
                rightLineNum: model.newLineNum
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
            }
        }

        ScrollBar {
            id: hScrollBar
            orientation: Qt.Horizontal
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            size: (diffListView.width *0.5) / diffListView.maxContentWidth
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
    function appendRow(type, lTxt, rTxt, lNum, rNum) {
        fileModel.append({
                             "type": type,
                             "leftText": lTxt,
                             "rightText": rTxt,
                             "oldLineNum": lNum,
                             "newLineNum": rNum
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

}
