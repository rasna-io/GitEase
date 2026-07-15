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

/**
 * Finds the start and end indices of a conflict block in the display model.
 * @param model      - ListModel to search
 * @param blockIndex - The block's index property (1‑based)
 * @returns { start: number, end: number } or { start: -1, end: -1 } if not found
 */
function findBlockRowRange(model, blockIndex) {
    let start = -1, end = -1
    for (let i = 0; i < model.count; ++i) {
        if (model.get(i).blockIndex === blockIndex) {
            if (start < 0) start = i
            end = i
        }
    }
    return { start, end }
}

/**
 * Finds a block object in an array by its index property.
 * @param blocks - Array of block objects (from selectedConflict.blocks)
 * @param idx    - The index property to look for
 * @returns { block: object, pos: number } or null
 */
function findBlockByIndex(blocks, idx) {
    for (let i = 0; i < blocks.length; ++i) {
        if (blocks[i].index === idx)
            return { block: blocks[i], pos: i }
    }
    return null
}

/**
 * Returns the lines that should replace a resolved conflict block.
 * @param block - The block object (with currentText, incomingText)
 * @param mode  - "ours", "theirs", or "both"
 * @returns String[] of resolved lines
 */
function computeResolvedLines(block, mode) {
    if (mode === "ours")
        return block.currentText  ? block.currentText.split("\n")  : []

    if (mode === "theirs")
        return block.incomingText ? block.incomingText.split("\n") : []

    if (mode === "both") {
        let ours   = block.currentText  ? block.currentText.split("\n")  : []
        let theirs = block.incomingText ? block.incomingText.split("\n") : []
        return ours.concat(theirs)
    }

    return []
}

/**
 * Replaces a conflict block's rows in the displayModel with resolved lines.
 * Also updates line numbers and blockIndex values of subsequent rows.
 * @param displayModel  - The ListModel
 * @param blockIndex    - The block's index (1‑based)
 * @param block         - The block object (needs startLine, endLine)
 * @param resolvedLines - The resolved text lines to insert
 */
function replaceBlockInModel(displayModel, blockIndex, block, resolvedLines) {
    let { start, end } = findBlockRowRange(displayModel, blockIndex)
    if (start < 0)
        return

    let removedRowCount     = end - start + 1
    let originalLineCount   = block.endLine - block.startLine + 1
    let lineDelta           = resolvedLines.length - originalLineCount

    // Remove old conflict rows
    displayModel.remove(start, removedRowCount)

    // Insert resolved rows
    for (let i = 0; i < resolvedLines.length; ++i) {
        displayModel.insert(start + i, {
            type: "line",
            text: resolvedLines[i],
            lineNumber: block.startLine + i,
            blockIndex: -1,
            role: "resolved"
        })
    }

    // Shift line numbers of rows after the block
    if (lineDelta !== 0) {
        for (let i = start + resolvedLines.length; i < displayModel.count; ++i) {
            let row = displayModel.get(i)
            if (row.lineNumber !== undefined && row.lineNumber !== null) {
                displayModel.setProperty(i, "lineNumber", row.lineNumber + lineDelta)
            }
        }
    }

    // Decrement blockIndex for later blocks
    for (let i = 0; i < displayModel.count; ++i) {
        let bi = displayModel.get(i).blockIndex
        if (bi !== undefined && bi > blockIndex) {
            displayModel.setProperty(i, "blockIndex", bi - 1)
        }
    }
}

/**
 * Updates the remaining blocks array after one block is resolved.
 * Renumbers indices and shifts line references accordingly.
 * @param selectedConflict  - The conflict object (must have a blocks array)
 * @param blockIndex        - The resolved block's original index
 * @param resolvedPos       - Position of the resolved block in the array
 * @param lineDelta         - Number of lines gained/lost
 * @param blockEndLine      - The original endLine of the resolved block
 */
function updateRemainingBlocks(selectedConflict, blockIndex, resolvedPos, lineDelta, blockEndLine) {
    for (let i = 0; i < selectedConflict.blocks.length; ++i) {
        if (i === resolvedPos)
            continue

        let b = selectedConflict.blocks[i]
        if (b.index > blockIndex)
            b.index -= 1

        if (b.startLine > blockEndLine) {
            b.startLine += lineDelta
            b.endLine   += lineDelta
        }
    }
    selectedConflict.blocks.splice(resolvedPos, 1)
}

/**
 * Replaces the conflict block in the raw file-lines array.
 * @param lines         - The lines array (selectedConflict.lines)
 * @param block         - The resolved block object (needs startLine, endLine)
 * @param resolvedLines - The resolved text lines
 * @returns The updated lines array
 */
function updateLinesArray(lines, block, resolvedLines) {
    if (!lines)
        return lines

    let prefix = lines.slice(0, block.startLine - 1)
    let suffix = lines.slice(block.endLine)
    return prefix.concat(resolvedLines, suffix)
}
