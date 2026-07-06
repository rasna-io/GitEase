/*! ***********************************************************************************************
 * GraphViewPresenter
 * ************************************************************************************************/
.pragma library

/* Property Declarations
 * ****************************************************************************************/
var selectedCommit      = "";
var selectedFilePath    = "";

var commitGraph         = null;
var fileChangesDock     = null;
var diffView            = null;
var statusController    = null;
var commitController    = null;

/* Functions
 * ****************************************************************************************/

/**
 * @brief Initializes the presenter with required dependencies.
 * @param {Object} deps - Dictionary containing references to UI components and controllers.
 */
function init(deps) {
    commitGraph         = deps.commitGraph;
    fileChangesDock     = deps.fileChangesDock;
    diffView            = deps.diffView;
    statusController    = deps.statusController;
    commitController    = deps.commitController;
}

/**
 * @brief Clears the currently selected commit and file, and resets the diff view.
 */
function clearSelection() {
    selectedCommit      = "";
    selectedFilePath    = "";
    diffView.diffData   = null;
}

/**
 * @brief Handles the event when a commit is clicked in the graph.
 * @param {string} commitId - The hash of the selected commit, or "__uncommitted__".
 */
function handleCommitClicked(commitId) {
    if (!fileChangesDock)
        return;

    selectedCommit = commitId;

    fileChangesDock.commitHash = commitId;

    if (commitId !== "__uncommitted__")
        return;

    var node = commitGraph.commits.find(function(c) { return c.hash === commitId; });
    if (node && node.isUncommitted) {
        var res = statusController.status();
        if (!res.success || !res.data) {
            fileChangesDock.files = [];
            return;
        }
        fileChangesDock.files = res.data;
    }
}

/**
 * @brief Handles the event when a file is selected in the file changes dock.
 *        Fetches the appropriate diff and updates the DiffView.
 * @param {string} filePath - The path of the selected file.
 */
function handleFileSelected(filePath) {
    selectedFilePath = filePath;
    var commitId = selectedCommit;
    if (!commitId)
        return;

    var node = commitGraph.commits ? commitGraph.commits.find(function(c) { return c.hash === commitId; }) : null;

    // uncommitted diff
    if (commitId === "__uncommitted__" || (node && node.isUncommitted)) {
        var headHash = statusController.getHeadHash();
        if (!headHash) {
            return;
        }
        var res = statusController.getWorkingDirectoryDiff(headHash, filePath);
        if (res && res.success)
            diffView.diffData = res.data;
        return;
    }

    // normal / stash commits
    var parentHash = "";

    // 1) stash: use stashParentId
    if (node && node.isStash && node.stashParentId) {
        parentHash = node.stashParentId;
    }
    // 2) try commitController.getParentHash
    else {
        parentHash = commitController.getParentHash(commitId);
    }
    // 3) fallback to first parent from node data
    if (!parentHash && node && node.parentHashes && node.parentHashes.length > 0) {
        parentHash = node.parentHashes[0];
    }

    if (!parentHash) {
        return;
    }

    var diffRes = statusController.getDiff(parentHash, commitId, filePath);
    if (diffRes && diffRes.success) {
        diffView.diffData = diffRes.data;
    }
}
