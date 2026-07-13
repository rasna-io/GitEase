import QtQuick

import GitEase

/*! ***********************************************************************************************
 * GitTreeController
 * Loads the repository file tree and file contents at a specific commit
 * for the Commit File Browser.
 * ************************************************************************************************/
GitTree {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    /*
     * Flat list of tree entries: {name, path, type ("blob"|"tree"), depth, parentPath}
     */
    property var    fileTreeModel       : []

    property string currentCommitSha    : ""
    property string currentFilePath     : ""
    property string currentFileContent  : ""
    property bool   currentFileIsBinary : false

    /* Signals
     * ****************************************************************************************/
    signal treeLoaded()
    signal treeLoadFailed(string errorMessage)
    signal fileContentLoaded(string filePath)
    signal fileContentLoadFailed(string errorMessage)

    /* Signals and Connections
     * ****************************************************************************************/
    onCurrentRepoChanged: clear()

    /* Functions
     * ****************************************************************************************/
    /**
     * Loads the full file tree at the given commit into fileTreeModel.
     */
    function loadTree(commitSha) {
        clearFileContent()

        var res = getFileTree(commitSha)
        if (!res.success) {
            root.currentCommitSha   = ""
            root.fileTreeModel      = []
            root.treeLoadFailed(res.errorMessage || "Failed to load file tree")
            return false
        }

        root.currentCommitSha   = commitSha
        root.fileTreeModel      = res.data
        root.treeLoaded()
        return true
    }

    /**
     * Loads the content of a single file at the given commit.
     */
    function loadFileContent(commitSha, filePath) {
        var res = getFileContent(commitSha, filePath)
        if (!res.success) {
            clearFileContent()
            root.fileContentLoadFailed(res.errorMessage || "Failed to load file content")
            return false
        }

        root.currentFilePath        = filePath
        root.currentFileIsBinary    = res.data.isBinary
        root.currentFileContent     = res.data.content
        root.fileContentLoaded(filePath)
        return true
    }
    /**
     * Clears the loaded file content state.
     */
    function clearFileContent() {
        root.currentFilePath        = ""
        root.currentFileContent     = ""
        root.currentFileIsBinary    = false
    }

    /**
     * Clears the whole controller state (e.g. on repository change).
     */
    function clear() {
        root.currentCommitSha    = ""
        root.fileTreeModel      = []
        clearFileContent()
    }
}
