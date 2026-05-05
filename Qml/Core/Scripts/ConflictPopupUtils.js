/*! ***********************************************************************************************
 * ConflictPopupUtils Script
 * Pure data manipulation for conflict resolution UI.
 * Handles building/updating the display model, line splitting/merging, and content extraction.
 * All functions are stateless and operate on QML objects passed as parameters.
 * ************************************************************************************************/

.pragma library

/**
 * Recomputes line numbers for all non‑button rows in the display model.
 * Line numbers are sequential, skipping blockButton rows.
 * Called after any insert/remove operation that changes the row order.
 *
 * @param displayModel - ListModel containing the conflict view rows
 */
function recomputeLineNumbers(displayModel) {
    var lineNum = 1;

    for (var i = 0; i < displayModel.count; i++) {
        var row = displayModel.get(i);

        if (row.type === "blockButton")
            continue;

        displayModel.setProperty(i, "lineNumber", lineNum);
        lineNum++;
    }
}

/**
 * Updates the maximum content width of the conflict ListView based on a new line of text.
 * This ensures the horizontal scrollbar appears when lines are long.
 *
 * @param newText          - Text of the line to measure
 * @param widthCalculator  - TextMetrics object used to calculate text width
 * @param conflictListView - ListView that contains the conflict editor
 */
function updateMaxContentWidth(newText, widthCalculator, conflictListView) {
    if (newText === undefined || newText === null)
        return;

    var visualText = newText.replace(/\t/g, "    ");
    widthCalculator.text = visualText;

    var measuredWidth = widthCalculator.width + 200;
    if (measuredWidth > conflictListView.maxContentWidth)
        conflictListView.maxContentWidth = measuredWidth;
}

/**
 * Builds the full file content as a single string from the current display model.
 * Skips blockButton rows (they are UI controls, not actual file lines).
 *
 * @param displayModel - ListModel containing the conflict view rows
 * @returns String with newline‑separated lines
 */
function buildFullContent(displayModel) {
    var lines = [];

    for (var i = 0; i < displayModel.count; i++) {
        var row = displayModel.get(i);

        if (row.type === "blockButton")
            continue

        lines.push(row.text)
    }
    return lines.join("\n");
}

/**
 * Builds or restores the display model from conflict data or cached user modifications.
 * Clears the existing model, then populates it with rows of type:
 * - contextLine (regular editable lines)
 * - blockLine (conflict zone lines, markers or ours/theirs content)
 * - blockButton (buttons to resolve a conflict block)
 *
 * @param selectedConflict - The current conflict file object from GitConflict
 * @param modifiedFiles    - Cache object storing user modifications per file path
 * @param selectedPath     - Path of the currently opened file
 * @param displayModel     - ListModel to populate
 * @param conflictListView - ListView used for the editor (needed for maxContentWidth reset)
 * @param widthCalculator  - TextMetrics object for width calculations
 */
function buildDisplayModel(selectedConflict, modifiedFiles, selectedPath, displayModel, conflictListView, widthCalculator) {
    displayModel.clear();
    conflictListView.maxContentWidth = 0

    if (!selectedConflict)
        return;

    if (modifiedFiles[selectedPath]) {
        var savedState = modifiedFiles[selectedPath];
        for (let i = 0; i < savedState.length; i++) {
            displayModel.append(savedState[i]);
            if (savedState[i].text)
                updateMaxContentWidth(savedState[i].text, widthCalculator, conflictListView);
        }
        return;
    }

    var lines   = selectedConflict.lines || [];
    var blocks  = selectedConflict.blocks || [];

    var blockMap = {};
    for (var b of blocks)
        blockMap[b.startLine] = b;

    var i = 0;
    var runningLine = 1;

    while (i < lines.length) {
        var lineNumber = i + 1;

        if (blockMap[lineNumber]) {
            var block = blockMap[lineNumber];

            displayModel.append({
                type: "blockButton",
                blockIndex: block.index
            });

            for (var j = 0; j < block.lines.length; j++) {
                var line = block.lines[j];
                displayModel.append({
                    type: "blockLine",
                    text: line.text,
                    blockIndex: block.index,
                    role: line.role,
                    lineNumber: runningLine
                });
                updateMaxContentWidth(line.text, widthCalculator, conflictListView);
                runningLine++;
            }
            i = block.endLine;
        }

        else {
            displayModel.append({
                type: "contextLine",
                text: lines[i],
                lineNumber: runningLine
            });
            updateMaxContentWidth(lines[i], widthCalculator, conflictListView);
            runningLine++;
            i++;
        }
    }
}

/**
 * Splits a line at the given cursor position.
 * Replaces the original line with the text before the cursor, and inserts a new line with the text after.
 * Recomputes line numbers afterwards and moves focus to the new line.
 *
 * @param displayModel     - ListModel containing rows
 * @param rowIndex         - Index of the row to split
 * @param cursorPos        - Character position inside the line where the split occurs
 * @param conflictListView - ListView used to update currentIndex
 */
function splitLine(displayModel, rowIndex, cursorPos, conflictListView) {
    var row = displayModel.get(rowIndex);

    if (!row || row.type === "blockButton")
        return;

    if (row.type === "blockLine" && (row.role === "marker-start" || row.role === "separator" || row.role === "marker-end"))
        return;

    var before  = row.text.substring(0, cursorPos);
    var after   = row.text.substring(cursorPos);

    displayModel.setProperty(rowIndex, "text", before);

    var newRow = {
        type: row.type,
        text: after,
        lineNumber:
        row.lineNumber + 1
    };

    if (row.blockIndex !== undefined) newRow.blockIndex = row.blockIndex;
    if (row.role !== undefined) newRow.role = row.role;

    displayModel.insert(rowIndex + 1, newRow);
    recomputeLineNumbers(displayModel);
    conflictListView.currentIndex = rowIndex + 1;
}

/**
 * Merges the current line into the previous line.
 * Appends the current line's text to the previous line's text, then deletes the current line.
 * Recomputes line numbers and moves focus to the merged line.
 *
 * @param displayModel     - ListModel containing rows
 * @param rowIndex         - Index of the row to merge up (will be removed)
 * @param conflictListView - ListView used to update currentIndex
 */
function mergeLineUp(displayModel, rowIndex, conflictListView) {
    if (rowIndex === 0)
        return;
    var current = displayModel.get(rowIndex);
    var prev = displayModel.get(rowIndex - 1);
    if (!current || !prev)
        return;

    if (current.type !== prev.type)
        return;

    if (current.type === "blockLine") {
        if (current.blockIndex !== prev.blockIndex || current.role !== prev.role)
            return;

        if (current.role === "marker-start" || current.role === "separator" || current.role === "marker-end")
            return;
    }

    var newText = prev.text + current.text;
    displayModel.setProperty(rowIndex - 1, "text", newText);
    displayModel.remove(rowIndex);
    recomputeLineNumbers(displayModel);
    conflictListView.currentIndex = rowIndex - 1;
}

