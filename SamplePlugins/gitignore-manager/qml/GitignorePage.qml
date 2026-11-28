import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEaseGitignore

import "qrc:/GitEase/Qml/Core/Scripts/AsyncGit.js" as AsyncGit

/*! ***********************************************************************************************
 * GitignorePage
 * Header with the view switch, then the repository files, the .gitignore and the templates.
 * Wide windows show the files beside the .gitignore / templates; narrow ones use three tabs.
 *
 * Git work goes through the host's libgit2 code, using controllers the host passes in:
 * ignoreController reads the status with ignored files and names the rule behind an ignored
 * path, statusController takes files out of the index. The plugin creates no controllers of its
 * own. GitignoreEngine only builds the page model and edits .gitignore and the templates.
 *
 * "Show hidden files" and the pattern style are saved in the plugin settings, so they persist
 * across sessions.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RepositoryController   repositoryController:   null
    property NotificationController notificationController: null
    //! Passed in by the host: ignored files and the rule behind an ignored path.
    property IgnoreController       ignoreController:       null
    //! Passed in by the host: takes files out of the index.
    property StatusController       statusController:       null
    property var                    gitStateNotifier:       null
    property var                    pluginManager:          null
    property string                 pluginId:               "com.gitease.gitignore-manager"

    property var    analysis:       null
    //! "files", "gitignore" or "templates". "files" only exists as a tab when the window is narrow.
    property string tab:            "files"
    property bool   showHidden:     false
    //! "exact", "name", "extension" or "folder".
    property string patternMode:    "exact"
    property bool   settingsLoaded: false
    property var    templates:      []

    readonly property string repoPath: repositoryController?.appModel?.currentRepository?.path ?? ""
    readonly property string repoName: repoPath.length > 0 ? repoPath.replace(/[\\/]+$/, "").split(/[\\/]/).pop() : ""
    readonly property bool   ready:    analysis !== null && analysis.success === true

    // Responsive breakpoints
    readonly property bool wide:         width >= Style.dp(1000)
    readonly property bool narrowHeader: width < Style.dp(640)
    readonly property real pagePadding:  width < Style.dp(700) ? Style.dp(12) : Style.dp(20)

    readonly property int changedCount: ready
        ? analysis.counts.modified + analysis.counts.staged + analysis.counts.added + analysis.counts.deleted
          + analysis.counts.renamed + analysis.counts.conflicted
        : 0

    //! The tab that is highlighted; in a wide window the files are always visible.
    readonly property string currentTab: wide && tab === "files" ? "gitignore" : tab

    readonly property var tabItems: {
        const items = []
        if (!wide)
            items.push({ key: "files", label: "Files", icon: Style.icons.folder,
                         count: ready ? String(analysis.counts.total) : "" })
        items.push({ key: "gitignore", label: ".gitignore", icon: Style.icons.file, count: "" })
        items.push({ key: "templates", label: "Templates", icon: Style.icons.list,
                     count: templates.length > 0 ? String(templates.length) : "" })
        return items
    }

    readonly property string subtitle: {
        if (repoName.length === 0)
            return "No repository open"
        if (!ready)
            return repoName
        const c = analysis.counts
        // The host names the state itself: "Detached HEAD", "initial/no-commits" or the branch.
        const where = analysis.branch
        return repoName + "  \u00b7  " + where + "  \u00b7  " + changedCount + " changed  \u00b7  "
               + c.untracked + " untracked  \u00b7  " + c.ignored + " ignored"
    }

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.pluginPageBackground

    onRepoPathChanged: {
        root.analysis = null
        refreshTimer.restart()
    }
    onPluginManagerChanged: loadSettings()
    Component.onCompleted: {
        loadSettings()
        refreshTimer.restart()
    }

    /* Functions
     * ****************************************************************************************/
    function onPageActivated() {
        refreshTimer.restart()
    }

    function loadSettings() {
        if (root.settingsLoaded || !root.pluginManager || !root.pluginId)
            return
        const hidden = root.pluginManager.pluginSetting(root.pluginId, "showHidden", false)
        root.showHidden = hidden === true || hidden === "true"

        const mode = root.pluginManager.pluginSetting(root.pluginId, "patternMode", "exact")
        root.patternMode = ["exact", "name", "extension", "folder"].indexOf(mode) !== -1 ? mode : "exact"
        root.settingsLoaded = true
    }

    function saveSetting(key, value) {
        if (root.pluginManager && root.pluginId)
            root.pluginManager.setPluginSetting(root.pluginId, key, value)
    }

    function setShowHidden(value) {
        root.showHidden = value
        root.saveSetting("showHidden", value)
    }

    function setPatternMode(mode) {
        root.patternMode = mode
        root.saveSetting("patternMode", mode)
    }

    //! The file or the index changed through this page: look again right away.
    function rescan() {
        if (root.repoPath.length > 0)
            root.startScan()
    }

    //! Reads the status through the host, then lets the engine build the page model from it.
    function startScan() {
        if (root.repoPath.length === 0 || !root.ignoreController || !root.ignoreController.currentRepo) {
            root.analysis = null
            return
        }

        const generation = ignoreEngine.beginScan()

        AsyncGit.call(root.ignoreController, "scan", [],
            result => {
                if (result && result.success)
                    ignoreEngine.finishScan(generation, result.data)
                else
                    ignoreEngine.failScan(generation,
                                          (result && result.errorMessage) || "Could not read the repository")
            },
            error => {
                if (error === AsyncGit.STALE)
                    ignoreEngine.cancelScan(generation)
                else
                    ignoreEngine.failScan(generation, error)
            })
    }

    /* Children
     * ****************************************************************************************/
    Connections {
        target: root.ignoreController
        ignoreUnknownSignals: true

        function onCurrentRepoChanged() {
            refreshTimer.restart()
        }
    }

    GitignoreEngine {
        id: ignoreEngine
        repoPath: root.repoPath

        onScanned: function(result) {
            root.analysis = result
        }

        Component.onCompleted: root.templates = ignoreEngine.templates()
    }

    Timer {
        id: refreshTimer
        interval: 300
        onTriggered: {
            if (root.repoPath.length === 0) {
                root.analysis = null
                return
            }
            if (ignoreEngine.busy)
                restart()
            else
                root.startScan()
        }
    }

    Connections {
        target: root.gitStateNotifier
        ignoreUnknownSignals: true

        function onRepositoryChanged() {
            refreshTimer.restart()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        GitignoreHeader {
            Layout.fillWidth: true
            Layout.preferredHeight: implicitHeight
            subtitle: root.subtitle
            tabs: root.tabItems
            currentTab: root.currentTab
            busy: ignoreEngine.busy
            canRefresh: root.repoPath.length > 0
            narrow: root.narrowHeader
            sidePadding: root.pagePadding

            onTabClicked: function(key) { root.tab = key }
            onRefreshRequested: refreshTimer.restart()
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.margins: root.pagePadding
            spacing: Style.dp(12)

            FilesView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.wide || root.tab === "files"

                engine: ignoreEngine
                ignoreController: root.ignoreController
                statusController: root.statusController
                analysis: root.analysis
                notificationController: root.notificationController
                showHidden: root.showHidden
                patternMode: root.patternMode
                loading: ignoreEngine.busy

                onChanged: root.rescan()
                onShowHiddenRequested: function(value) { root.setShowHidden(value) }
                onPatternModeRequested: function(mode) { root.setPatternMode(mode) }
            }

            StackLayout {
                id: sideStack

                Layout.fillHeight: true
                Layout.fillWidth: !root.wide
                Layout.preferredWidth: root.wide ? Math.max(Style.dp(400), root.width * 0.38) : -1
                visible: root.wide || root.tab !== "files"
                currentIndex: root.tab === "templates" ? 1 : 0

                onCurrentIndexChanged: sideFade.restart()

                NumberAnimation {
                    id: sideFade
                    target: sideStack
                    property: "opacity"
                    from: 0
                    to: 1
                    duration: Style.motionPage
                    easing.type: Easing.OutCubic
                }

                GitignoreView {
                    engine: ignoreEngine
                    analysis: root.analysis
                    notificationController: root.notificationController
                    templates: root.templates

                    onChanged: root.rescan()
                    onOpenTemplates: root.tab = "templates"
                }

                TemplatesView {
                    engine: ignoreEngine
                    analysis: root.analysis
                    notificationController: root.notificationController
                    templates: root.templates

                    onChanged: {
                        root.rescan()
                        root.tab = "gitignore"
                    }
                    onTemplatesModified: root.templates = ignoreEngine.templates()
                }
            }
        }
    }
}
