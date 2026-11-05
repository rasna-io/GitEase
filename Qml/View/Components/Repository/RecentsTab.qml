import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RecentsTab
 * Search + list of recent repositories. Exposes the chosen path via `selectedPath` and emits
 * `accepted()` on double-click.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property RepositoryController repositoryController: null
    property var    recentRepositories: []
    property string selectedPath: ""
    property string search: ""

    readonly property var filtered: {
        var q = root.search.toLowerCase()
        var list = root.recentRepositories || []
        if (q === "")
            return list
        return list.filter(function(r) {
            return r && (((r.name || "").toLowerCase().indexOf(q) >= 0)
                         || ((r.path || "").toLowerCase().indexOf(q) >= 0))
        })
    }

    /* Signals
     * ****************************************************************************************/
    signal accepted()

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 320

    property var missingPaths: ({})

    property string missingPath: ""

    onRecentRepositoriesChanged     : root.checkFolders()
    onRepositoryControllerChanged   : root.checkFolders()
    Component.onCompleted           : root.checkFolders()

    /* Functions
     * ****************************************************************************************/
    function reset() {
        root.selectedPath = ""
        root.search = ""
        searchField.text = ""
        root.checkFolders()
    }

    function relocate(path) {
        root.missingPath = path
        folderDialog.open()
    }

    function checkFolders() {
        var missing = {}
        var ctrl = root.repositoryController
        if (ctrl) {
            for (var r of (root.recentRepositories || [])) {
                if (r && !ctrl.folderExists(r.path))
                    missing[r.path] = true
            }
        }
        root.missingPaths = missing
    }

    function colorOf(m) {
        var ctrl = root.repositoryController
        if (!ctrl)
            return (m && m.color) ? m.color : Style.colors.repositoryAvatarDefault
        return ctrl.isValidRepoColor(m ? m.color : "")
                ? m.color
                : ctrl.repoColor(m ? m.path : "")
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RepoTextField {
            id: searchField
            placeholderText: "Search recent repos..."
            icon: Style.icons.search
            onTextChanged: root.search = text
        }

        ScrollView {
            id: recentsScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth
            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            ColumnLayout {
                width: recentsScroll.availableWidth - (recentsScroll.ScrollBar.vertical.size < 1 ? 14 : 0)
                spacing: 6

                Text {
                    visible: root.filtered.length === 0
                    Layout.fillWidth: true
                    Layout.topMargin: 20
                    text: "No recent repositories"
                    horizontalAlignment: Text.AlignHCenter
                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.captionPt
                    color: Style.colors.mutedText
                }

                Repeater {
                    model: root.filtered

                    RecentRepositoryRow {
                        Layout.fillWidth: true
                        repoName: modelData?.name ?? ""
                        repoPath: modelData?.path ?? ""
                        avatarColor: root.colorOf(modelData)
                        isExists: !root.missingPaths[modelData?.path ?? ""]
                        selected: isExists && root.selectedPath !== "" && root.selectedPath === (modelData?.path ?? "")
                        onDoubleClicked: {
                            if (!isExists)
                                return
                            root.selectedPath = modelData?.path ?? ""
                            root.accepted()
                        }
                        onRelocateRequested: root.relocate(modelData?.path ?? "")
                        onRemoveRequested: root.repositoryController.removeRecent(modelData?.path ?? "")
                    }
                }
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: root.missingPath !== "" ? "Select the new location of " + root.missingPath
                                       : "Select Repository Folder"
        currentFolder: root.repositoryController?.appModel?.appSettings?.generalSettings?.defaultPath ?? ""

        onAccepted: {
            const oldPath = root.missingPath
            root.missingPath = ""

            if (!folderDialog.selectedFolder)
                return

            const controller = root.repositoryController
            const newPath = controller.appModel.fileIO.pathNormalizer(folderDialog.selectedFolder.toString())

            // Fix the entry in place; the user then confirms with Continue like any other entry
            if (controller.relocateRecent(oldPath, newPath)) {
                root.checkFolders()   // the list may be unchanged (same folder picked again)
                root.selectedPath = newPath
            } else if (controller.notificationController) {
                controller.notificationController.error("This repository is no longer in the recent list.", "Repository relocate failed", 5000)
            }
        }

        onRejected: root.missingPath = ""
    }
}
