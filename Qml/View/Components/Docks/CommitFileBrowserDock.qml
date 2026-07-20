import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * CommitFileBrowserDock
 * Browse the full repository file tree at a specific commit (read-only),
 * similar to GitHub's "Browse files" on a commit.
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property GitTreeController      gitTreeController       : null
    property RepositoryController   repositoryController    : null
    property NotificationController notificationController  : null
    property StatusController       statusController        : null

    property string commitSha       : ""
    property string commitMessage   : ""

    readonly property string commitShortSha: commitSha ? commitSha.substring(0, 7) : ""

    // Paths of folders currently expanded in the tree
    property var expandedPaths      : ({})

    property var selectedEntry      : null

    property var childCounts        : ({})

    property var changedFiles       : ({})
    property var changedFolders     : ({})

    property string searchText      : ""

    property int            treeColumnWidth     : root.width * 0.3
    readonly property int   minTreeColumnWidth  : 160

    // File icon colours by depth (cycling)
    readonly property var fileDepthColors: [
        Style.colors.foreground,
        Style.colors.secondaryText,
        Style.colors.accent,
        Style.colors.error,
        Style.colors.addedFile,
        Style.colors.deletededFile,
        Style.colors.modifiediedFile,
        Style.colors.renamedFile,
        Style.colors.untrackedFile,
        Style.colors.warning
    ]

    /* Signals
     * ****************************************************************************************/
    signal closeRequested()

    /* Object Properties
     * ****************************************************************************************/
    width: Math.min(880, parent ? parent.width - 24 : 880)
    height: Math.min(620, parent ? parent.height - 24 : 620)
    modal: true
    closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

    onClosed: clear()

    /* Signals and Connections
     * ****************************************************************************************/
    Connections {
        target: repositoryController

        function onCurrentRepoChanged() {
            root.clear()
            root.closeRequested()
        }
    }

    /* Children
     * ****************************************************************************************/
    TextEdit {
        id: clipboardHelper
        visible: false
    }

    ListModel {
        id: treeModel
    }

    FileDialog {
        id: saveFileDialog
        title: "Save file as"
        fileMode: FileDialog.SaveFile

        onAccepted: {
            var targetPath = selectedFile.toString().replace(new RegExp("^file://+"), "")
            var res = root.gitTreeController.saveFileContent(root.commitSha,
                                                             root.gitTreeController.currentFilePath,
                                                             targetPath)

            if (res.success)
                root.notificationController.success("File saved to " + targetPath, "Commit File Browser", 3000)
            else
                root.notificationController.error(res.errorMessage || "Failed to save file", "Commit File Browser", 5000)
        }
    }

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 8
        clip: true
        border.color: Style.colors.primaryBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 1
            spacing: 0

            // Header: folder icon, title, SHA, message, detach, close
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                color: Style.colors.secondaryBackground

                // bottom border
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 1
                    color: Style.colors.primaryBorder
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 14
                    anchors.rightMargin: 14
                    spacing: 10

                    // Folder icon
                    Text {
                        text: Style.icons.folder
                        Layout.preferredWidth: 13
                        Layout.preferredHeight: 13
                        color: Style.colors.warning
                    }

                    // Title
                    Label {
                        text: "Browse files at commit"
                        color: Style.colors.titleText
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    // SHA
                    Label {
                        text: root.commitShortSha
                        color: Style.colors.accent
                        font.family: Style.fontTypes.monospace
                        font.pixelSize: 11
                    }

                    // Message
                    Label {
                        text: root.commitMessage
                        color: Style.colors.mutedText
                        font.family: Style.fontTypes.monospace
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

                    // Close button
                    ToolButton {
                        id: closeButton
                        Layout.preferredWidth: 22
                        Layout.preferredHeight: 22
                        hoverEnabled: true

                        contentItem: Text {
                            anchors.centerIn: parent
                            text: Style.icons.close
                            font.family: Style.fontTypes.font6ProSolid
                            font.pixelSize: 10
                            color: parent.hovered ? Style.colors.foreground : Style.colors.mutedText
                        }

                        background: Rectangle {
                            radius: 5
                            color: parent.hovered ? Style.colors.hoverTitle : "transparent"
                        }

                        onClicked: {
                            root.close()
                            root.closeRequested()
                        }
                    }
                }
            }

            // Body: tree panel + content panel
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                // Tree Panel (left)
                Rectangle {
                    id: treePanel
                    Layout.preferredWidth: Math.max(root.minTreeColumnWidth, root.treeColumnWidth)
                    Layout.fillHeight: true
                    color: Style.colors.primaryBackground
                    clip: true

                    EmptyStateView {
                        title: "No files to show"
                        details: "The file tree of this commit is empty"
                        visible: treeModel.count === 0
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Search bar
                        Rectangle{
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            color: "transparent"

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: Style.colors.primaryBorder
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 10
                                anchors.topMargin: 4
                                anchors.bottomMargin: 4
                                spacing: 6

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 5
                                    color: Style.colors.surfaceLight

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 9
                                        spacing: 6

                                        // Search icon
                                        Text {
                                            Layout.preferredWidth: 10
                                            Layout.preferredHeight: 10
                                            text: Style.icons.search
                                            font.family: Style.fontTypes.font6ProSolid
                                            font.pixelSize: 10
                                            color: Style.colors.mutedText
                                        }

                                        // Search text field
                                        TextField {
                                            id: searchField
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            placeholderText: "Search files..."
                                            placeholderTextColor: Style.colors.mutedText
                                            color: Style.colors.foreground
                                            font.family: Style.fontTypes.monospace
                                            font.pixelSize: 11
                                            background: Item{}
                                            onTextChanged: {
                                                root.searchText = text.toLowerCase()
                                                root.rebuildTreeModel()
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // Tree list
                        ListView {
                            id: treeListView
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            model: treeModel
                            clip: true

                            ScrollBar.vertical: ScrollBar {}

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 24

                                property var    entryData   : model
                                property bool   isFolder    : entryData.type === "tree"
                                property bool   isExpanded  : root.expandedPaths[entryData.path] === true

                                property bool   isHovered   : false
                                property bool   isSelected  : root.selectedEntry && root.selectedEntry.path === entryData.path

                                color: {
                                    if (isSelected) return Style.colors.accent
                                    if (isHovered)  return Style.colors.hoverTitle
                                    return "transparent"
                                }

                                radius: 4

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6 + entryData.depth * 14
                                    anchors.rightMargin: 6
                                    spacing: 5

                                    // Chevron (folders) or change-status tag (files)
                                    Item {
                                        Layout.preferredWidth: 12
                                        Layout.fillHeight: true

                                        Text {
                                            anchors.centerIn: parent
                                            visible: isFolder
                                            text: isExpanded ? Style.icons.caretDown : Style.icons.caretRight
                                            font.family: Style.fontTypes.font6ProSolid
                                            font.pixelSize: 9
                                            color: Style.colors.mutedText
                                            horizontalAlignment: Text.AlignHCenter
                                        }

                                        FileStatusTag {
                                            anchors.centerIn: parent
                                            compact: true
                                            deltaStatus: !isFolder && root.changedFiles[entryData.path] !== undefined
                                                         ? root.changedFiles[entryData.path]
                                                         : -1
                                        }
                                    }

                                    // Icon (folder/file)
                                    Text {
                                        text: isFolder ? Style.icons.folder : Style.icons.file
                                        font.family: Style.fontTypes.font6ProSolid
                                        font.pixelSize: 10
                                        color: isFolder ? Style.colors.warning : root.fileIconColor(entryData.depth)
                                    }

                                    // Name
                                    Label {
                                        Layout.fillWidth: true
                                        text: entryData.name
                                        color: isSelected ? Style.colors.selectedText : Style.colors.foreground
                                        font.family: Style.fontTypes.monospace
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    // LED
                                    Rectangle {
                                        Layout.preferredWidth: 5
                                        Layout.preferredHeight: 5
                                        radius: 2.5
                                        color: Style.colors.modifiediedFile
                                        visible: isFolder && root.changedFolders[entryData.path] === true
                                    }

                                    // Direct-children count (folders only)
                                    Label {
                                        // visible: isFolder
                                        visible: false
                                        text: root.childCounts[entryData.path] || ""
                                        color: Style.colors.mutedText
                                        font.family: Style.fontTypes.monospace
                                        font.pixelSize: 10
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.handleEntryClicked(entryData, index)
                                    onEntered: isHovered = true
                                    onExited: isHovered = false
                                }
                            }
                        }
                    }
                }

                // Resize handle
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: treeDividerMouseArea.pressed ? Style.colors.resizeHandlePressed : Style.colors.resizeHandle

                    MouseArea {
                        id: treeDividerMouseArea
                        anchors.fill: parent
                        anchors.leftMargin: -5
                        anchors.rightMargin: -5
                        hoverEnabled: true
                        cursorShape: Qt.SizeHorCursor
                        preventStealing: true

                        onPositionChanged: function(mouse) {
                            if (!pressed)
                                return

                            // Track the absolute mouse position (scene coordinates) so the
                            // handle follows the cursor without drift or jitter.
                            var sceneX      = mapToItem(null, mouse.x, 0).x
                            var panelLeft   = treePanel.mapToItem(null, 0, 0).x
                            var maxWidth    = root.width - 280

                            root.treeColumnWidth = Math.max(root.minTreeColumnWidth,
                                                            Math.min(sceneX - panelLeft, maxWidth))
                        }
                    }
                }

                // Content Panel (right)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: Style.colors.secondaryBackground
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // File info bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            color: Style.colors.primaryBackground
                            visible: root.gitTreeController && root.gitTreeController.currentFilePath !== ""

                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                height: 1
                                color: Style.colors.primaryBorder
                            }

                            RowLayout {
                                id: fileSettingslay
                                anchors.fill: parent
                                anchors.leftMargin: 14
                                anchors.rightMargin: 14
                                spacing: 8

                                // File icon
                                Text {
                                    Layout.preferredWidth: 12
                                    Layout.preferredHeight: 12
                                    text: Style.icons.file
                                    font.family: Style.fontTypes.font6ProSolid
                                    font.pixelSize: 10
                                    color: Style.colors.accent
                                }

                                // File path
                                Label {
                                    Layout.fillWidth: true
                                    text: root.gitTreeController ? root.gitTreeController.currentFilePath : ""
                                    color: Style.colors.foreground
                                    font.family: Style.fontTypes.monospace
                                    font.pixelSize: 12
                                    elide: Text.ElideLeft
                                }

                                // "READ ONLY" badge
                                Rectangle {
                                    Layout.preferredHeight: 20
                                    Layout.preferredWidth: readOnlyLabel.width + 12
                                    radius: 3
                                    color: Qt.rgba(1,0,0,0.1)
                                    border.color: Qt.rgba(248/255,113/255,113/255,0.2)
                                    border.width: 1
                                    Label {
                                        id: readOnlyLabel
                                        anchors.centerIn: parent
                                        text: "READ ONLY"
                                        color: Style.colors.error
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 9
                                        font.bold: true
                                    }
                                }

                                // Copy button
                                ToolButton {
                                    id: copyButton
                                    Layout.preferredWidth: 60
                                    Layout.preferredHeight: 20
                                    Layout.alignment: Qt.AlignVCenter
                                    hoverEnabled: true
                                    enabled: root.gitTreeController && !root.gitTreeController.currentFileIsBinary

                                    contentItem: Item {
                                        anchors.fill: parent

                                        RowLayout {
                                            spacing: 4
                                            anchors.centerIn: parent

                                            Text {
                                                text: Style.icons.copy
                                                font.family: Style.fontTypes.font6ProSolid
                                                font.pixelSize: 9
                                                color: copyButton.hovered ? Style.colors.foreground : Style.colors.mutedText
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Label {
                                                text: "Copy"
                                                font.pixelSize: 11
                                                color: copyButton.hovered ? Style.colors.foreground : Style.colors.mutedText
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }
                                    }

                                    background: Rectangle {
                                        radius: 4
                                        color: copyButton.hovered ? Style.colors.hoverTitle : "transparent"
                                    }

                                    onClicked: root.copyCurrentFileContent()
                                }


                                // Save button
                                ToolButton {
                                    id: saveButton
                                    Layout.preferredWidth: 60
                                    Layout.preferredHeight: 20
                                    Layout.alignment: Qt.AlignVCenter
                                    hoverEnabled: true

                                    contentItem: Item {
                                        anchors.fill: parent

                                        RowLayout {
                                            spacing: 4
                                            anchors.centerIn: parent

                                            Text {
                                                text: Style.icons.download
                                                font.family: Style.fontTypes.font6ProSolid
                                                font.pixelSize: 9
                                                color: saveButton.hovered ? Style.colors.foreground : Style.colors.mutedText
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Label {
                                                text: "Save"
                                                font.pixelSize: 11
                                                color: saveButton.hovered ? Style.colors.foreground : Style.colors.mutedText
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }
                                    }

                                    background: Rectangle {
                                        radius: 4
                                        color: saveButton.hovered ? Style.colors.hoverTitle : "transparent"
                                    }

                                    onClicked: root.saveCurrentFileAs()
                                }
                            }
                        }

                        // Content area

                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true

                            // No file selected placeholder
                            EmptyStateView {
                                title: "No file selected"
                                details: "Select a file from the tree to view its content at this commit"
                                visible: !root.gitTreeController || root.gitTreeController.currentFilePath === ""
                            }

                            // Binary file placeholder
                            EmptyStateView {
                                title: "Binary file"
                                details: "This file cannot be displayed. Use \"Save as...\" to export it."
                                visible: root.gitTreeController
                                         && root.gitTreeController.currentFilePath !== ""
                                         && root.gitTreeController.currentFileIsBinary
                            }

                            // Code viewer with line numbers
                            ListView {
                                id: codeView
                                anchors.fill: parent
                                visible: root.gitTreeController
                                         && root.gitTreeController.currentFilePath !== ""
                                         && !root.gitTreeController.currentFileIsBinary

                                clip: true
                                ScrollBar.vertical: ScrollBar {}

                                model: root.gitTreeController ? root.gitTreeController.currentFileContent.split('\n') : []

                                delegate: RowLayout {
                                    width: codeView.width
                                    height: 20
                                    spacing: 0

                                    // Line number gutter
                                    Rectangle {
                                        Layout.preferredWidth: 44
                                        Layout.fillHeight: true
                                        color: "transparent"

                                        Rectangle {
                                            anchors.right: parent.right
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            width: 1
                                            color: Qt.rgba(1, 1, 1, 0.04)
                                        }

                                        Label {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: index + 1
                                            color: Style.colors.lineNumberColor
                                            font.family: Style.fontTypes.monospace
                                            font.pixelSize: 11
                                            horizontalAlignment: Text.AlignRight
                                        }
                                    }

                                    // Code line
                                    Label {
                                        Layout.fillWidth: true
                                        Layout.fillHeight: true
                                        text: modelData
                                        color: Style.colors.foreground
                                        font.family: Style.fontTypes.monospace
                                        font.pixelSize: 12
                                        wrapMode: Text.NoWrap
                                        elide: Text.ElideNone
                                        padding: 12
                                        verticalAlignment: Text.AlignVCenter

                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    // Opens the browser for a commit and loads its file tree.
    function openForCommit(hash, message) {
        clear()

        root.commitSha      = hash
        root.commitMessage  = message || ""

        if (root.gitTreeController.loadTree(hash)) {
            rebuildChildCounts()
            loadCommitChanges(hash)
            rebuildTreeModel()
        }

        else
            root.notificationController.error("Failed to load file tree for commit " + root.commitShortSha,
                                                  "Commit File Browser", 5000)

        root.open()
    }

    // Load the files changed in this commit and mark their ancestor folders
    function loadCommitChanges(hash) {
        root.changedFiles   = ({})
        root.changedFolders = ({})

        if (!root.statusController)
            return

        var res = root.statusController.getCommitFileChanges(hash)
        if (!res.success || !res.data)
            return

        var files   = ({})
        var folders = ({})

        for (var i = 0; i < res.data.length; i++) {
            var file = res.data[i]
            files[file.path] = file.deltaStatus

            // Mark every ancestor folder as containing a change
            var parts   = file.path.split("/")
            var current = ""
            for (var j = 0; j < parts.length - 1; j++) {
                current = current === "" ? parts[j] : current + "/" + parts[j]
                folders[current] = true
            }
        }

        root.changedFiles   = files
        root.changedFolders = folders
    }

    // Count direct children of every folder in the loaded tree
    function rebuildChildCounts() {
        var all    = root.gitTreeController.fileTreeModel || []
        var counts = ({})

        for (var i = 0; i < all.length; i++) {
            var parentPath = all[i].parentPath
            if (parentPath !== "")
                counts[parentPath] = (counts[parentPath] || 0) + 1
        }

        root.childCounts = counts
    }

    // Full rebuild of the tree rows (used on open and when the search changes)
    function rebuildTreeModel() {
        treeModel.clear()

        var all = root.gitTreeController.fileTreeModel || []
        for (var i = 0; i < all.length; i++) {
            var entry = all[i]
            if (isEntryVisible(entry) && matchesSearch(entry))
                treeModel.append(entry)
        }
    }

    function isEntryVisible(entry) {
        return entry.parentPath === "" || isPathVisible(entry.parentPath)
    }

    function isPathVisible(folderPath) {
        var parts = folderPath.split("/")
        var current = ""

        for (var i = 0; i < parts.length; i++) {
            current = current === "" ? parts[i] : current + "/" + parts[i]
            if (root.expandedPaths[current] !== true)
                return false
        }

        return true
    }

    function matchesSearch(entry) {
        if (root.searchText === "")
            return true

        return entry.name.toLowerCase().indexOf(root.searchText) !== -1
            || entry.path.toLowerCase().indexOf(root.searchText) !== -1
    }

    // Insert the visible rows of an expanded folder right below it.
    function expandFolderRows(folderPath, rowIndex) {
        var all      = root.gitTreeController.fileTreeModel || []
        var prefix   = folderPath + "/"
        var insertAt = rowIndex + 1
        var started  = false

        for (var i = 0; i < all.length; i++) {
            var entry = all[i]

            if (!started) {
                if (entry.path === folderPath)
                    started = true
                continue
            }

            if (entry.path.indexOf(prefix) !== 0)
                break

            if (isEntryVisible(entry) && matchesSearch(entry))
                treeModel.insert(insertAt++, entry)
        }
    }

    // Remove the rows of a collapsed folder.
    function collapseFolderRows(folderPath, rowIndex) {
        var prefix = folderPath + "/"

        while (rowIndex + 1 < treeModel.count
               && treeModel.get(rowIndex + 1).path.indexOf(prefix) === 0)
            treeModel.remove(rowIndex + 1)
    }

    function handleEntryClicked(entry, rowIndex) {
        root.selectedEntry = { path: entry.path, type: entry.type }

        if (entry.type === "tree") {
            var expanded   = root.expandedPaths
            var willExpand = expanded[entry.path] !== true
            expanded[entry.path] = willExpand
            root.expandedPaths = expanded

            if (willExpand)
                expandFolderRows(entry.path, rowIndex)
            else
                collapseFolderRows(entry.path, rowIndex)

            return
        }

        if (!root.gitTreeController.loadFileContent(root.commitSha, entry.path))
            root.notificationController.error("Failed to load " + entry.path, "Commit File Browser", 5000)
    }

    function copyCurrentFileContent() {
        if (root.gitTreeController.currentFilePath === "")
            return

        clipboardHelper.text = root.gitTreeController.currentFileContent
        clipboardHelper.selectAll()
        clipboardHelper.copy()

        root.notificationController.success("File content copied to clipboard", "Commit File Browser", 2500)
    }

    function saveCurrentFileAs() {
        if (root.gitTreeController.currentFilePath === "")
            return

        var fileName = root.gitTreeController.currentFilePath.split("/").pop()
        saveFileDialog.currentFile = "file:///" + fileName
        saveFileDialog.open()
    }

    function clear() {
        root.commitSha              = ""
        root.commitMessage          = ""
        root.expandedPaths          = ({})
        root.selectedEntry          = null
        root.childCounts            = ({})
        root.changedFiles           = ({})
        root.changedFolders         = ({})
        treeModel.clear()

        root.searchText             = ""
        searchField.text            = ""
    }

    function fileIconColor(depth) {
        return fileDepthColors[depth % fileDepthColors.length]
    }
}
