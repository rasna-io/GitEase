/*! ***********************************************************************************************
 * GraphViewPresenter
 * Handles commit/file interaction logic for GraphViewPage.
 * Must be initialized with dependencies before use.
 * ************************************************************************************************/
.pragma library

var selectedCommit = "";
var selectedFilePath = "";

var commitGraph = null;
var fileChangesDock = null;
var diffView = null;
var statusController = null;
var commitController = null;

function init(deps) {
    commitGraph = deps.commitGraph;
    fileChangesDock = deps.fileChangesDock;
    diffView = deps.diffView;
    statusController = deps.statusController;
    commitController = deps.commitController;
}

function clearSelection() {
    selectedCommit = "";
    selectedFilePath = "";
    if (diffView)
        diffView.diffData = null;
}

function handleCommitClicked(commitId) {
    selectedCommit = commitId;
    if (fileChangesDock)
        fileChangesDock.commitHash = commitId;

    if (commitId !== "__uncommitted__")
        return;

    // uncommitted node
    if (!statusController)
        return;

    var node = commitGraph ? commitGraph.commits.find(function(c) { return c.hash === commitId; }) : null;
    if (node && node.isUncommitted) {
        var res = statusController.status();
        if (!res.success || !res.data) {
            console.log("status failed:", res);
            if (fileChangesDock) fileChangesDock.files = [];
            return;
        }
        fileChangesDock.files = res.data;
    }
}

function handleFileSelected(filePath) {
    selectedFilePath = filePath;
    var commitId = selectedCommit;
    if (!commitId || !commitGraph || !diffView)
        return;

    var node = commitGraph.commits ? commitGraph.commits.find(function(c) { return c.hash === commitId; }) : null;

    // uncommitted diff
    if (commitId === "__uncommitted__" || (node && node.isUncommitted)) {
        if (!statusController) return;
        var headHash = statusController.getHeadHash();
        if (!headHash) {
            console.log("HEAD is null -> cannot diff uncommitted");
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
    else if (commitController) {
        parentHash = commitController.getParentHash(commitId);
    }
    // 3) fallback to first parent from node data
    if (!parentHash && node && node.parentHashes && node.parentHashes.length > 0) {
        parentHash = node.parentHashes[0];
    }

    if (!parentHash) {
        console.log("Cannot determine parent for commit", commitId);
        return;
    }

    var diffRes = statusController.getDiff(parentHash, commitId, filePath);
    if (diffRes && diffRes.success) {
        diffView.diffData = diffRes.data;
    } else if (diffRes) {
        console.log("getDiff failed:", diffRes.errorMessage);
    }
}
