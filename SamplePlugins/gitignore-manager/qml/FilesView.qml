import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl
import GitEaseGitignore

import "FileTree.js" as FileTree

/*! ***********************************************************************************************
 * FilesView
 * Every file of the repository with its status, as a tree. Select files or whole folders to add
 * them to .gitignore, to stop ignoring them, or to stop tracking files that are already committed.
 *
 * The tree rows come from FileTree.js; this item keeps the state (filter, expanded folders,
 * selection) and runs the actions. The page owns the scan and the persisted preferences and is
 * told about both through signals.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property GitignoreEngine        engine:                 null
    //! The host's git access: ignored files and the rule behind an ignored path.
    property IgnoreController       ignoreController:       null
    //! Takes files out of the index.
    property StatusController       statusController:       null
    property var                    analysis:               null
    property NotificationController notificationController: null
    property bool                   showHidden:             false
    //! "exact", "name", "extension" or "folder".
    property string                 patternMode:            "exact"
    property bool                   loading:                false

    //! "all", "changes", "untracked", "ignored", "committed" or "trackedIgnored".
    property string filter:      "all"
    property string search:      ""
    property bool   alsoUntrack: true

    //! Path -> true. Files by path, whole folders by "folder/".
    property var  selected:      ({})
    property int  selectedCount: 0
    property var  visibleFiles:  []
    property var  stats:         ({ all: 0, changes: 0, untracked: 0, ignored: 0, committed: 0, trackedIgnored: 0 })

    //! Folder path -> true/false, set by the user; folders follow autoExpand until then.
    property var  expanded:      ({})
    property var  rows:          []
    property var  folderChanged: ({})
    //! While searching or filtering, folders open by themselves so matches are visible, but only
    //! the small ones: a folder with more than autoExpandLimit files stays closed until opened.
    readonly property bool autoExpand: search.trim().length > 0 || filter !== "all"
    readonly property int  autoExpandLimit: 5
    //! Folder path -> number of visible files below it, from the last build.
    property var  folderTotals:  ({})

    readonly property bool ready:    analysis !== null && analysis.success === true
    readonly property var  allFiles: ready ? analysis.files : []

    readonly property var selection: FileTree.analyseSelection(selected, allFiles)
    readonly property var patternPreview: selection.toIgnore.length > 0 && engine
                                          ? engine.patternsFor(selection.toIgnore, patternMode) : []

    /* Signals
     * ****************************************************************************************/
    //! .gitignore or the index changed; the page rescans.
    signal changed()
    signal showHiddenRequested(bool value)
    signal patternModeRequested(string mode)

    /* Object Properties
     * ****************************************************************************************/
    // Deferred: reading allFiles inside the selection binding can fire this handler while that
    // binding is still being evaluated, and writing "selected" from here would loop.
    onAllFilesChanged: Qt.callLater(syncWithFiles)
    onShowHiddenChanged: rebuild()
    onFilterChanged:     rebuild()
    onSearchChanged:     rebuild()
    onExpandedChanged:   buildRows()
    onAutoExpandChanged: buildRows()

    /* Functions
     * ****************************************************************************************/
    //! The repository was scanned again: drop selections that vanished and rebuild the tree.
    function syncWithFiles() {
        const kept = FileTree.pruneSelection(selected, allFiles)
        selected = kept.selected
        selectedCount = kept.count
        rebuild()
    }

    function rebuild() {
        const result = FileTree.filterFiles(allFiles, showHidden, search, filter)
        stats = result.stats
        visibleFiles = result.list
        buildRows()
    }

    function buildRows() {
        const tree = FileTree.buildRows(visibleFiles, isExpanded)
        folderChanged = tree.changed
        folderTotals = tree.totals
        rows = tree.rows
    }

    function isExpanded(path, fileCount) {
        const state = expanded[path]
        if (state !== undefined)
            return state

        const count = fileCount !== undefined ? fileCount : (folderTotals[path] || 0)
        return autoExpand && count <= autoExpandLimit
    }

    function setExpanded(path, value) {
        const next = Object.assign({}, expanded)
        next[path] = value
        expanded = next
    }

    //! Opens every folder (\a open true) or closes them all so only the top level shows.
    function setAllExpanded(open) {
        const next = {}
        for (const folder of FileTree.folderPaths(visibleFiles))
            next[folder] = open
        expanded = next
    }

    //! Folders of the visible tree that are open / closed right now.
    function folderCounts() {
        let open = 0
        let closed = 0
        for (const folder of FileTree.folderPaths(visibleFiles)) {
            if (isExpanded(folder))
                open++
            else
                closed++
        }
        return { open: open, closed: closed }
    }

    function copyText(text, what) {
        clipboardHelper.text = text
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        clipboardHelper.deselect()
        root.notificationController?.success(what + " copied to the clipboard", "Gitignore", 2000)
    }

    //! Opens \a folder (a path relative to the repository) in the system file manager.
    function showInFileManager(folder) {
        const base = analysis && analysis.root ? analysis.root : ""
        if (base.length === 0)
            return
        Qt.openUrlExternally("file:///" + base + (folder.length > 0 ? "/" + folder : ""))
    }

    //! The entries a right-click on \a row offers.
    function menuEntriesFor(row) {
        const entries = []
        const danger = Style.colors.contextMenuDanger

        if (row.kind === "folder") {
            const target = FileTree.analyseSelection({ [row.path + "/"]: true }, allFiles)
            const open = isExpanded(row.path)
            const selectedNow = selected[row.path + "/"] === true

            entries.push({ text: "Ignore this folder", icon: Style.icons.plus,
                           enabled: row.status !== "ignored",
                           action: function() { root.ignoreEntries(target.toIgnore, "exact", target.tracked) } })
            entries.push({ text: "Ignore every folder named \"" + row.name + "\"", icon: Style.icons.plus,
                           enabled: row.status !== "ignored",
                           action: function() { root.ignoreEntries(target.toIgnore, "name", target.tracked) } })
            entries.push({ separator: true })
            entries.push({ text: selectedNow ? "Deselect folder" : "Select folder", icon: Style.icons.check,
                           action: function() { root.toggleFolder(row.path) } })
            entries.push({ text: open ? "Collapse this folder" : "Expand this folder",
                           icon: open ? Style.icons.caretUp : Style.icons.caretDown,
                           action: function() { root.setExpanded(row.path, !open) } })
            entries.push({ separator: true })
            entries.push({ text: "Copy path", icon: Style.icons.copy,
                           action: function() { root.copyText(row.path, "Path") } })
            entries.push({ text: "Show in file manager", icon: Style.icons.folder,
                           action: function() { root.showInFileManager(row.path) } })
            return entries
        }

        const f = row.file
        const target = FileTree.analyseSelection({ [f.path]: true }, allFiles)
        const hasRule = f.status === "ignored" || f.trackedIgnored
        const dot = f.name.lastIndexOf(".")
        const selectedNow = selected[f.path] === true

        if (!hasRule) {
            entries.push({ text: f.isDir ? "Ignore this folder" : "Ignore this file", icon: Style.icons.plus,
                           action: function() { root.ignoreEntries(target.toIgnore, "exact", target.tracked) } })
            if (!f.isDir && dot > 0 && dot < f.name.length - 1)
                entries.push({ text: "Ignore all *" + f.name.substring(dot) + " files", icon: Style.icons.plus,
                               action: function() { root.ignoreEntries(target.toIgnore, "extension", target.tracked) } })
            entries.push({ text: "Ignore everything named \"" + f.name + "\"", icon: Style.icons.plus,
                           action: function() { root.ignoreEntries(target.toIgnore, "name", target.tracked) } })
            if (f.dir.length > 0)
                entries.push({ text: "Ignore the folder \"" + f.dir + "\"", icon: Style.icons.plus,
                               action: function() { root.ignoreEntries(target.toIgnore, "folder", target.tracked) } })
        }
        if (hasRule)
            entries.push({ text: "Stop ignoring", icon: Style.icons.minus,
                           action: function() { root.planUnignore([f.path]) } })
        if (f.trackedIgnored)
            entries.push({ text: "Stop tracking (keep on disk)", icon: Style.icons.trash, color: danger,
                           action: function() { root.untrackPaths([f.path]) } })

        entries.push({ separator: true })
        entries.push({ text: selectedNow ? "Deselect" : "Select", icon: Style.icons.check,
                       action: function() { root.toggle(f.path) } })
        entries.push({ separator: true })
        entries.push({ text: "Copy path", icon: Style.icons.copy,
                       action: function() { root.copyText(f.path, "Path") } })
        entries.push({ text: "Show in file manager", icon: Style.icons.folder,
                       action: function() { root.showInFileManager(f.dir) } })
        return entries
    }

    //! Right-click: the clicked row decides the entries, the tree state decides expand / collapse.
    function openContextMenu(scenePosition) {
        const local = fileList.mapFromItem(null, scenePosition.x, scenePosition.y)
        const index = fileList.indexAt(local.x + fileList.contentX, local.y + fileList.contentY)
        const counts = folderCounts()
        treeMenu.openFor(scenePosition, index >= 0 ? menuEntriesFor(rows[index]) : [],
                         counts.closed > 0, counts.open > 0)
    }

    function setSelected(next) {
        selected = next
        selectedCount = Object.keys(next).length
    }

    function toggle(path) {
        const next = Object.assign({}, selected)
        if (next[path])
            delete next[path]
        else
            next[path] = true
        setSelected(next)
    }

    //! Selects the folder itself: one rule such as /build/ instead of every file in it.
    function toggleFolder(folder) {
        const key = folder + "/"
        const next = Object.assign({}, selected)
        if (next[key]) {
            delete next[key]
        } else {
            // The folder rule covers everything inside, so drop what was picked individually.
            for (const path in next) {
                if (path.indexOf(key) === 0)
                    delete next[path]
            }
            next[key] = true
        }
        setSelected(next)
    }

    function selectVisible() {
        const next = Object.assign({}, selected)
        for (let i = 0; i < visibleFiles.length; i++) {
            if (!FileTree.isCovered(selected, visibleFiles[i].path))
                next[visibleFiles[i].path] = true
        }
        setSelected(next)
    }

    function clearSelection() {
        setSelected({})
    }

    function pathsOf(list) {
        return list.map(f => f.path)
    }

    function fail(title, message) {
        root.notificationController?.error(message, title, 7000)
    }

    //! Writes the rules for \a entries; \a tracked are the committed files to take out of the index.
    function ignoreEntries(entries, mode, tracked) {
        const patterns = engine.patternsFor(entries, mode)
        if (patterns.length === 0)
            return

        const added = engine.addPatterns(patterns)
        if (!added.success) {
            fail("Could not update .gitignore", added.errorMessage)
            return
        }

        let untracked = 0
        const trackedPaths = pathsOf(tracked)
        if (alsoUntrack && trackedPaths.length > 0) {
            const removed = root.removeFromIndex(trackedPaths)
            if (!removed.success) {
                fail("Could not stop tracking", removed.errorMessage)
                root.changed()
                return
            }
            untracked = trackedPaths.length
        }

        let message = added.added === 1 ? "Added 1 rule to .gitignore" : "Added " + added.added + " rules to .gitignore"
        if (added.skipped > 0)
            message += " (" + added.skipped + " already there)"
        if (untracked > 0)
            message += "; " + untracked + " file(s) removed from the index"
        root.notificationController?.success(message, "Gitignore", 3500)
        root.changed()
    }

    function ignoreSelected() {
        ignoreEntries(selection.toIgnore, patternMode, selection.tracked)
        clearSelection()
    }

    //! git rm --cached through the host; the result has the shape of the engine's operations.
    function removeFromIndex(paths) {
        if (!statusController)
            return { success: false, errorMessage: "Git is not available" }

        const result = statusController.removeFromIndex(paths)
        return { success: result.success, errorMessage: result.errorMessage }
    }

    function untrackPaths(paths) {
        if (paths.length === 0)
            return
        const result = root.removeFromIndex(paths)
        if (!result.success) {
            fail("Could not stop tracking", result.errorMessage)
            return
        }
        root.notificationController?.success(paths.length + " file(s) removed from the index; they stay on disk",
                                             "Gitignore", 3500)
        root.changed()
    }

    function untrackSelected() {
        untrackPaths(pathsOf(selection.trackedIgnored))
        clearSelection()
    }

    //! Looks up the rules that ignore \a paths and asks before removing them.
    function planUnignore(paths) {
        const hits = ignoreController ? ignoreController.checkIgnore(paths) : null
        if (!hits || !hits.success) {
            fail("Could not check the rules", hits ? hits.errorMessage : "Git is not available")
            return
        }

        const plan = engine.planUnignore(paths, hits.data)
        if (!plan.success) {
            fail("Could not check the rules", plan.errorMessage)
            return
        }
        unignoreDialog.plan = plan
        unignoreDialog.itemCount = paths.length
        unignoreDialog.open()
    }

    function confirmUnignore() {
        const rules = unignoreDialog.rules.filter(r => r.editable).map(r => ({ line: r.line, pattern: r.pattern }))
        const result = engine.removeRules(rules)
        unignoreDialog.close()
        if (!result.success) {
            fail("Could not update .gitignore", result.errorMessage)
            root.changed()
            return
        }
        root.notificationController?.success("Removed " + result.removed + " rule(s) from .gitignore",
                                             "Gitignore", 3500)
        clearSelection()
        root.changed()
    }

    /* Children
     * ****************************************************************************************/
    GitignoreCard {
        anchors.fill: parent

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.dp(14)
            spacing: Style.dp(10)

            FileFilterBar {
                Layout.fillWidth: true
                search: root.search
                showHidden: root.showHidden
                filter: root.filter
                stats: root.stats

                onSearchEdited: function(text) { root.search = text }
                onShowHiddenToggled: function(value) { root.showHiddenRequested(value) }
                onFilterSelected: function(key) { root.filter = key }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: Style.dp(10)
                visible: root.ready

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: {
                        const n = root.visibleFiles.length
                        let t = n + (n === 1 ? " item" : " items")
                        if (root.analysis && root.analysis.truncated)
                            t += "  \u00b7  list limited to the first " + root.allFiles.length + " files"
                        return t
                    }
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.microPt
                    color: Style.colors.pluginCardMetaText
                }

                GitignoreTextLink {
                    visible: root.visibleFiles.length > 0
                    text: "Select all"
                    onClicked: root.selectVisible()
                }

                GitignoreTextLink {
                    visible: root.selectedCount > 0
                    text: "Clear"
                    onClicked: root.clearSelection()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Style.colors.pluginDivider
            }

            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                // Right-click: actions for the row under the pointer, plus expand / collapse all.
                TapHandler {
                    acceptedButtons: Qt.RightButton
                    onTapped: function(eventPoint) { root.openContextMenu(eventPoint.scenePosition) }
                }

                ListView {
                    id: fileList
                    anchors.fill: parent
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: root.rows
                    reuseItems: true

                    ScrollBar.vertical: ScrollBar {}

                    delegate: FileTreeRow {
                        id: treeRow

                        required property var modelData

                        width: ListView.view.width - Style.dp(12)
                        rowData: modelData
                        open: root.isExpanded(modelData.path)
                        covered: FileTree.isCovered(root.selected, modelData.path)
                        selected: covered || root.selected[modelData.kind === "folder" ? modelData.path + "/"
                                                                                       : modelData.path] === true
                        hasChanges: root.folderChanged[modelData.path] === true

                        onToggled: {
                            if (treeRow.isFolder)
                                root.toggleFolder(modelData.path)
                            else
                                root.toggle(modelData.path)
                        }
                        onExpandToggled: root.setExpanded(modelData.path, !treeRow.open)
                    }
                }

                GitignoreEmptyState {
                    anchors.centerIn: parent
                    width: Math.min(parent.width - Style.dp(32), Style.dp(380))
                    visible: !root.ready || root.visibleFiles.length === 0
                    busy: root.loading && !root.ready
                    iconText: !root.analysis ? Style.icons.folder
                            : !root.ready ? Style.icons.warning : Style.icons.search
                    iconColor: root.analysis && !root.ready ? Style.colors.warning : Style.colors.accent
                    title: !root.analysis ? (root.loading ? "Reading files..." : "Open a repository")
                         : !root.ready ? "Can't read the repository"
                         : "No files to show"
                    message: !root.analysis ? ""
                           : !root.ready ? root.analysis.errorMessage
                           : root.search.length > 0 || root.filter !== "all"
                             ? "Nothing matches the current search and filters."
                             : !root.showHidden && root.analysis.counts.hidden > 0
                               ? "Only hidden files are here. Turn on \"Hidden files\" to see them."
                               : "This repository has no files yet."
                }
            }

            FileSelectionBar {
                selectedCount: root.selectedCount
                selection: root.selection
                patternMode: root.patternMode
                patternPreview: root.patternPreview
                alsoUntrack: root.alsoUntrack

                onPatternModeRequested: function(mode) { root.patternModeRequested(mode) }
                onAlsoUntrackRequested: function(value) { root.alsoUntrack = value }
                onIgnoreRequested: root.ignoreSelected()
                onUnignoreRequested: root.planUnignore(root.pathsOf(root.selection.toUnignore))
                onUntrackRequested: root.untrackSelected()
            }
        }
    }

    TextEdit {
        id: clipboardHelper
        visible: false
    }

    TreeContextMenu {
        id: treeMenu

        expandText: "Expand all folders"
        collapseText: "Collapse all folders"

        onExpandAllRequested: root.setAllExpanded(true)
        onCollapseAllRequested: root.setAllExpanded(false)
    }

    UnignoreDialog {
        id: unignoreDialog

        onConfirmed: root.confirmUnignore()
    }
}
