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

    property string commitSha       : ""
    property string commitMessage   : ""

    readonly property string commitShortSha: commitSha ? commitSha.substring(0, 7) : ""

    // Paths of folders currently expanded in the tree
    property var expandedPaths      : ({})

    // All entries after applying visibility (ancestors expanded)
    property var visibleEntries     : []

    // Final filtered list (search + visibility)
    property var filteredVisibleEntries : []

    property var selectedEntry      : null

    property var childCounts        : ({})

    property string searchText      : ""

    property int            treeColumnWidth     : root.width * 0.3
    readonly property int   minTreeColumnWidth  : 160

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

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            // Header: folder icon, title, SHA, message, close
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 36
                color: Style.colors.primaryBackground
                border.color: Qt.rgba(1,1,1,0.07)
                border.width: 0

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
                        color: "#f59e0b"
                    }

                    // Title
                    Label {
                        text: root.title
                        color: Style.colors.titleText
                        font.family: Style.fontTypes.roboto
                        font.pixelSize: 12
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    // SHA
                    Label {
                        text: root.commitShortSha
                        color: "#3b82f6"
                        font.family: Style.fontTypes.monospace
                        font.pixelSize: 11
                    }

                    // Message
                    Label {
                        text: root.commitMessage
                        color: "#3d4452"
                        font.family: Style.fontTypes.monospace
                        font.pixelSize: 11
                        elide: Text.ElideRight
                        maximumLineCount: 1
                    }

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
                            color: parent.hovered ? Style.colors.foreground : "#6b7685"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }

                        background: Rectangle {
                            radius: 5
                            color: parent.hovered ? Qt.rgba(1,1,1,0.07) : "transparent"
                        }

                        onClicked: {
                            root.detached = false
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
                    Layout.preferredWidth: Math.max(root.minTreeColumnWidth, root.treeColumnWidth)
                    Layout.fillHeight: true
                    color: Style.colors.primaryBackground
                    clip: true

                    EmptyStateView {
                        title: "No files to show"
                        details: "The file tree of this commit is empty"
                        visible: !root.visibleEntries || root.visibleEntries.length === 0
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // Search bar
                        Rectangle{
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            color: Style.colors.primaryBackground

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
                                    color: Qt.rgba(1, 1, 1, 0.05)

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
                                            color: "#4a5260"
                                            horizontalAlignment: Text.AlignHCenter
                                            verticalAlignment  : Text.AlignVCenter
                                        }

                                        // Search text field
                                        TextField {
                                            id: searchField
                                            Layout.fillWidth: true
                                            Layout.fillHeight: true
                                            placeholderText: "Search files..."
                                            color: "#8b95a3"
                                            font.family: Style.fontTypes.monospace
                                            font.pixelSize: 11
                                            background: Item{}
                                            onTextChanged: {
                                                root.searchText = text.toLowerCase()
                                                root.rebuildFilteredEntries()
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
                            model: root.filteredVisibleEntries
                            clip: true

                            ScrollBar.vertical: ScrollBar {}

                            delegate: Rectangle {
                                width: ListView.view.width
                                height: 24

                                property var    entryData   : modelData
                                property bool   isFolder    : entryData.type === "tree"
                                property bool   isExpanded  : root.expandedPaths[entryData.path] === true

                                property bool   isHovered   : false
                                property bool   isSelected  : root.selectedEntry && root.selectedEntry.path === entryData.path

                                color: {
                                    if (isSelected)
                                        return "#1e2a3a"

                                    else if (isHovered)
                                        return Qt.rgba(1,1,1,0.04)

                                    return "transparent"
                                }

                                radius: 4

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 6 + entryData.depth * 14
                                    anchors.rightMargin: 6
                                    spacing: 5

                                    // Chevron (only for folders)
                                    Text {
                                        Layout.preferredWidth: 10
                                        text: isFolder ? (isExpanded ? Style.icons.caretDown : Style.icons.caretRight) : ""
                                        font.family: Style.fontTypes.font6ProSolid
                                        font.pixelSize: 9
                                        color: Style.colors.mutedText
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    // Icon (folder/file)
                                    Text {
                                        text: isFolder ? Style.icons.folder : Style.icons.file
                                        font.family: Style.fontTypes.font6ProSolid
                                        font.pixelSize: 10
                                        color: isFolder ? Style.colors.titleText : Style.colors.mutedText
                                    }

                                    // Name
                                    Label {
                                        Layout.fillWidth: true
                                        text: entryData.name
                                        color: Style.colors.foreground
                                        font.family: Style.fontTypes.roboto
                                        font.pixelSize: 12
                                        elide: Text.ElideRight
                                    }

                                    // Direct-children count (folders only)
                                    Label {
                                        visible: isFolder
                                        text: root.childCounts[entryData.path] || ""
                                        color: Style.colors.mutedText
                                        font.family: Style.fontTypes.monospace
                                        font.pixelSize: 10
                                    }
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    onClicked: root.handleEntryClicked(entryData)
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

                        property real   startX      : 0
                        property int    startWidth  : 0

                        onPressed: function(mouse) {
                            startX      = mapToItem(root, mouse.x, 0).x
                            startWidth  = root.treeColumnWidth
                        }

                        onPositionChanged: function(mouse) {
                            if (!pressed)
                                return

                            var currentX = mapToItem(root, mouse.x, 0).x
                            root.treeColumnWidth = Math.max(root.minTreeColumnWidth, startWidth + currentX - startX)
                        }
                    }
                }

                // Content Panel (right)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    color: "#0a0b0e"
                    clip: true

                    ColumnLayout {
                        anchors.fill: parent
                        spacing: 0

                        // File info bar
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            color: Style.colors.secondaryBackground
                            visible: root.gitTreeController.currentFilePath !== ""

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
                                    color: "#9175ff"
                                }

                                // File path
                                Label {
                                    Layout.fillWidth: true
                                    text: root.gitTreeController.currentFilePath
                                    color: Style.colors.mutedText
                                    font.family: Style.fontTypes.roboto
                                    font.pixelSize: 12
                                    elide: Text.ElideLeft
                                }

                                // "READ ONLY" badge
                                Rectangle {
                                    Layout.preferredHeight: 20
                                    Layout.preferredWidth: readOnlyLabel.width + 12
                                    radius: 3
                                    color: Qt.rgba(248/255,113/255,113/255,0.1)
                                    border.color: Qt.rgba(248/255,113/255,113/255,0.2)
                                    border.width: 1
                                    Label {
                                        id: readOnlyLabel
                                        anchors.centerIn: parent
                                        text: "READ ONLY"
                                        color: "#f87171"
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
                                                color: copyButton.hovered ? Style.colors.foreground : "#6b7685"
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Label {
                                                text: "Copy"
                                                font.pixelSize: 11
                                                color: copyButton.hovered ? Style.colors.foreground : "#6b7685"
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }
                                    }

                                    background: Rectangle {
                                        radius: 4
                                        color: copyButton.hovered ? Qt.rgba(1,1,1,0.05) : "transparent"
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
                                                color: saveButton.hovered ? Style.colors.foreground : "#6b7685"
                                                Layout.alignment: Qt.AlignVCenter
                                            }

                                            Label {
                                                text: "Save"
                                                font.pixelSize: 11
                                                color: saveButton.hovered ? Style.colors.foreground : "#6b7685"
                                                Layout.alignment: Qt.AlignVCenter
                                            }
                                        }
                                    }

                                    background: Rectangle {
                                        radius: 4
                                        color: saveButton.hovered ? Qt.rgba(1,1,1,0.05) : "transparent"
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
                                        border.color: Qt.rgba(1,1,1,0.04)
                                        border.width: 0

                                        Label {
                                            anchors.right: parent.right
                                            anchors.rightMargin: 12
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: index + 1
                                            color: "#3d4452"
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
                                        color: "#a0b0c0"
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
            rebuildVisibleEntries()
        }

        else
            root.notificationController.error("Failed to load file tree for commit " + root.commitShortSha,
                                                  "Commit File Browser", 5000)

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

    // Rebuild visible entries (respecting expanded folders)
    function rebuildVisibleEntries() {
        var all     = root.gitTreeController.fileTreeModel || []
        var visible = []

        for (var i = 0; i < all.length; i++) {
            var entry = all[i]
            if (entry.parentPath === "" || isPathVisible(entry.parentPath))
                visible.push(entry)
        }

        root.visibleEntries = visible
        rebuildFilteredEntries()
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

    // Further filter by search text
    function rebuildFilteredEntries() {
        var list = root.visibleEntries || []
        if (root.searchText === "") {
            root.filteredVisibleEntries = list
            return
        }

        var filtered = []
        for (var i = 0; i < list.length; i++) {
            var entry = list[i]
            if (entry.name.toLowerCase().indexOf(root.searchText) !== -1 ||
                entry.path.toLowerCase().indexOf(root.searchText) !== -1)
                filtered.push(entry)
        }
        root.filteredVisibleEntries = filtered
    }

    function handleEntryClicked(entry) {
        root.selectedEntry = entry

        if (entry.type === "tree") {
            var expanded = root.expandedPaths
            expanded[entry.path] = expanded[entry.path] !== true
            root.expandedPaths = expanded
            rebuildVisibleEntries()
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
        root.visibleEntries         = []
        root.filteredVisibleEntries = []

        root.searchText             = ""
        searchField.text            = ""
    }
}
