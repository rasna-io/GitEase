import QtQuick

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * ImageDiffHost
 * When the selected extension has a diff-plugin viewer, writes each blob to a
 * temp file with GitTree.saveFileContent() and shows that viewer instead of
 * the text diff. Temp files go away when the selection changes or this view closes.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var    pluginManager: null
    property GitTree gitTree: null
    property string repositoryPath: ""
    property string filePath: ""
    //! "workdir" working copy, "index" staged blob, "commit" newRevision.
    property string imageSource: "workdir"
    property string oldRevision: "HEAD"
    property string newRevision: ""

    property int  revision: 0
    property bool suspended: false
    property var  tempPaths: []
    property url  oldImageUrl: ""
    property url  newImageUrl: ""

    readonly property string cleanPath: (root.filePath || "").replace(/ ●$/, "")
    readonly property string viewerUrl: root.viewerUrlFor(root.filePath)
    readonly property bool active: root.viewerUrl.length > 0
                                   && root.cleanPath.length > 0
                                   && root.gitTree !== null

    /* Object Properties
     * ****************************************************************************************/
    visible: root.active && !root.suspended

    onFilePathChanged: root.scheduleReload()
    onImageSourceChanged: root.scheduleReload()
    onOldRevisionChanged: root.scheduleReload()
    onNewRevisionChanged: root.scheduleReload()
    onRepositoryPathChanged: root.scheduleReload()
    onGitTreeChanged: root.scheduleReload()
    onViewerUrlChanged: root.scheduleReload()

    Component.onCompleted: root.scheduleReload()
    Component.onDestruction: root.discardNow(root.tempPaths.concat(discardTimer.paths))

    /* Children
     * ****************************************************************************************/
    Timer {
        id: reloadTimer
        interval: 0
        repeat: false
        onTriggered: root.reload()
    }

    Timer {
        id: discardTimer
        interval: 1500
        repeat: false
        property var paths: []
        onTriggered: {
            root.discardNow(paths)
            paths = []
        }
    }

    Loader {
        id: viewerLoader
        anchors.fill: parent
        active: root.active && !root.suspended && root.viewerUrl.length > 0
        source: root.viewerUrl

        onLoaded: {
            if (!item)
                return
            item.repositoryPath = Qt.binding(() => root.repositoryPath)
            item.filePath = Qt.binding(() => root.cleanPath)
            item.oldImageUrl = Qt.binding(() => root.oldImageUrl)
            item.newImageUrl = Qt.binding(() => root.newImageUrl)
        }
    }

    Text {
        anchors.centerIn: parent
        visible: viewerLoader.status === Loader.Error
        text: qsTr("Not a readable image")
        color: Style.colors.error
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.mediumPt
    }

    Connections {
        target: root.pluginManager
        ignoreUnknownSignals: true

        function onPluginAboutToUnload(id) {
            root.suspended = true
            Qt.callLater(() => {
                root.suspended = false
                root.revision++
            })
        }

        function onPluginLoaded(id) {
            root.revision++
        }

        function onPluginsChanged() {
            root.revision++
        }
    }

    /* Functions
     * ****************************************************************************************/
    function hasViewer(filePath) {
        return root.viewerUrlFor(filePath).length > 0
    }

    function viewerUrlFor(filePath) {
        root.revision
        if (!root.pluginManager || root.extensionOf(filePath).length === 0)
            return ""
        const url = root.pluginManager.diffPluginUrlFor(root.extensionOf(filePath))
        return url ? url.toString() : ""
    }

    function extensionOf(filePath) {
        const name = (filePath || "").replace(/ ●$/, "").split(/[\\/]/).pop().toLowerCase()
        const dot = name.lastIndexOf(".")
        return dot >= 0 ? name.substring(dot + 1) : ""
    }

    function scheduleReload() {
        reloadTimer.restart()
    }

    function takeBlob(revision, repoPath) {
        if (!root.gitTree || !revision || !repoPath)
            return ""
        const temp = root.gitTree.makeTempImagePath(root.extensionOf(repoPath))
        const res = root.gitTree.saveFileContent(revision, repoPath, temp)
        return res && res.success ? temp : ""
    }

    function loadOld() {
        const revision = root.oldRevision || "HEAD"
        const direct = root.takeBlob(revision, root.cleanPath)
        if (direct)
            return direct

        const previous = root.gitTree.previousPath(root.cleanPath, revision, root.imageSource, root.newRevision)
        if (!previous || previous === root.cleanPath)
            return ""
        return root.takeBlob(revision, previous)
    }

    function loadNew() {
        if (root.imageSource === "index") {
            const temp = root.gitTree.makeTempImagePath(root.extensionOf(root.cleanPath))
            const res = root.gitTree.saveIndexFileContent(root.cleanPath, temp)
            return res && res.success ? temp : ""
        }

        if (root.imageSource === "commit")
            return root.newRevision ? root.takeBlob(root.newRevision, root.cleanPath) : ""

        if (!root.repositoryPath)
            return ""

        const absolute = root.gitTree.absoluteWorkdirFile(root.repositoryPath, root.cleanPath)
        return root.gitTree.localFileExists(absolute) ? absolute : ""
    }

    function reload() {
        const previous = root.tempPaths
        root.tempPaths = []
        root.oldImageUrl = ""
        root.newImageUrl = ""

        if (!root.active) {
            root.queueDiscard(previous)
            return
        }

        const created = []
        const oldPath = root.loadOld()
        if (oldPath)
            created.push(oldPath)

        const newPath = root.loadNew()
        const newIsTemp = root.imageSource === "index" || root.imageSource === "commit"
        if (newPath && newIsTemp)
            created.push(newPath)

        root.tempPaths = created
        root.oldImageUrl = oldPath ? root.gitTree.localFileUrl(oldPath) : ""
        root.newImageUrl = newPath ? root.gitTree.localFileUrl(newPath) : ""
        root.queueDiscard(previous)
    }

    function queueDiscard(paths) {
        if (!paths || paths.length === 0)
            return
        discardTimer.paths = discardTimer.paths.concat(paths)
        discardTimer.restart()
    }

    function discardNow(paths) {
        if (!paths || paths.length === 0 || !root.gitTree)
            return
        root.gitTree.discardTempFiles(paths)
    }
}
