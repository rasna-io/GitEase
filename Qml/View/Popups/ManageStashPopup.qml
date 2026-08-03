import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ManageStashPopup
 * ************************************************************************************************/

IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property StashController  stashController:  null
    property StatusController statusController: null
    property CommitController commitController: null

    property var    stashEntry:       null
    property var    stashFiles:       []
    property var    stashDiffData:    []
    property string selectedFilePath: ""

    readonly property bool canPerformAction: root.stashEntry !== null

    readonly property string stashRef: root.stashEntry ? `stash@{${root.stashEntry.index}}` : ""

    readonly property string headerTitle: {
        let message = root.stashEntry ? (root.stashEntry.message || "").trim() : ""
        return message.length > 0 ? message : qsTr("Stash")
    }

    //! branch • base commit • file count • date, in the order git itself reports them
    readonly property string headerMeta: {
        if (!root.stashEntry)
            return ""

        let parts = []

        let branchMatch = /^(?:WIP on|On) ([^:]+):/.exec(root.stashEntry.message || "")
        if (branchMatch)
            parts.push(branchMatch[1].trim())

        let baseId = root.stashEntry.parentId || root.stashEntry.id || ""
        if (baseId.length > 0)
            parts.push(baseId.substring(0, 7))

        parts.push(root.stashFiles.length === 1 ? qsTr("1 file")
                                               : qsTr("%1 files").arg(root.stashFiles.length))

        if (root.stashEntry.dateTime)
            parts.push(Qt.formatDateTime(root.stashEntry.dateTime, "MMM d, yyyy hh:mm"))

        return parts.join("  •  ")
    }

    readonly property var fileEntries: {
        let entries = []
        for (let i = 0; i < root.stashFiles.length; ++i) {
            let file = root.stashFiles[i]
            entries.push({
                path:        file.path,
                statusText:  root.statusLabel(file.deltaStatus),
                statusColor: root.statusColor(file.deltaStatus),
                additions:   file.additionsCount || 0,
                deletions:   file.deletionsCount || 0
            })
        }
        return entries
    }

    readonly property int totalAdditions: {
        let total = 0
        for (let i = 0; i < root.stashFiles.length; ++i)
            total += root.stashFiles[i].additionsCount || 0
        return total
    }

    readonly property int totalDeletions: {
        let total = 0
        for (let i = 0; i < root.stashFiles.length; ++i)
            total += root.stashFiles[i].deletionsCount || 0
        return total
    }

    /* Object Properties
     * ****************************************************************************************/
    width: 800
    height: 650
    padding: 0

    onStashEntryChanged: {
        if (!root.stashEntry || !root.statusController) {
            root.stashFiles = []
            root.stashDiffData = []
            root.selectedFilePath = ""
            return
        }

        // Load the list of files for this stash
        let loadFiles = root.statusController.getCommitFileChanges(root.stashEntry.id)
        if (loadFiles.success) {
            root.stashFiles = loadFiles.data

            // Automatically select the first file
            if (root.stashFiles.length > 0) {
                root.selectFile(root.stashFiles[0].path)
            } else {
                root.stashDiffData = []
                root.selectedFilePath = ""
            }
        }
    }

    /* Children
     * ****************************************************************************************/
    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 6
        clip: true
        border.color: Style.colors.primaryBorder
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Style.dp(3)
            spacing: 0

            StashPopupHeader {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 6

                title:    root.headerTitle
                stashRef: root.stashRef
                metaText: root.headerMeta

                onCloseRequested: root.close()
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                spacing: 10

                CheckBox {
                    id: reinstateIndexCheck
                    Layout.alignment: Qt.AlignVCenter
                    padding: 0
                    checked: true
                    text: "Restore staged / index state"

                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt

                    Material.accent: Style.colors.accent
                    Material.foreground: Style.colors.foreground

                    palette {
                        text: Style.colors.foreground
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    visible: root.totalAdditions > 0
                    text: `+${root.totalAdditions}`
                    color: Style.colors.conflictStatusAddedColor
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.captionPt
                }

                Text {
                    visible: root.totalDeletions > 0
                    text: `-${root.totalDeletions}`
                    color: Style.colors.conflictStatusConflictColor
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.captionPt
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.primaryBorder
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0

                StashFileList {
                    files:        root.fileEntries
                    currentPath:  root.selectedFilePath
                    sectionTitle: "FILES IN STASH"
                    emptyText:    "This stash carries no files"

                    onFileSelected: (path) => root.selectFile(path)
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Style.colors.primaryBorder
                }

                DiffView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    readOnly: true
                    diffData: root.stashDiffData
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: Style.colors.primaryBorder
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 10
                Layout.bottomMargin: 10
                spacing: 10

                ConflictPillButton {
                    Layout.preferredHeight: Style.dp(30)
                    text: "Drop stash"
                    leadingText: Style.icons.trash
                    accentColor: Style.colors.conflictDestructive
                    actionEnabled: root.canPerformAction
                    tooltip: "Delete this stash without applying it — the shelved changes are gone for good"
                    onClicked: {
                        root.executeAction("remove")
                        root.close()
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                ConflictPillButton {
                    Layout.preferredHeight: Style.dp(30)
                    text: "Apply"
                    accentColor: Style.colors.mutedText
                    actionEnabled: root.canPerformAction
                    tooltip: "Restore these changes and keep the stash in the list"
                    onClicked: {
                        root.executeAction("apply")
                        root.close()
                    }
                }

                ConflictPillButton {
                    Layout.preferredHeight: Style.dp(30)
                    text: "Pop"
                    trailingText: Style.icons.arrowRight
                    accentColor: Style.colors.accent
                    prominent: root.canPerformAction
                    actionEnabled: root.canPerformAction
                    tooltip: "Restore these changes and remove the stash from the list"
                    onClicked: {
                        root.executeAction("pop")
                        root.close()
                    }
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function selectFile(filePath) {
        root.selectedFilePath = filePath
        root.loadDiffForFile()
    }

    function loadDiffForFile() {
        root.stashDiffData = []
        if (!root.stashEntry || !root.selectedFilePath || !root.statusController)
            return

        const parentHash = root.stashEntry.parentId
                           || (root.commitController ? root.commitController.getParentHash(root.stashEntry.id) : "")

        if (!parentHash)
            return

        let res = root.statusController.getDiff(parentHash, root.stashEntry.id, root.selectedFilePath)
        if (res.success) {
            root.stashDiffData = res.data
        }
    }

    function executeAction(action) {
        if (!root.stashEntry || !root.stashController)
            return

        let result = ({ success: false })
        if (action === "apply") {
            result = root.stashController.apply(root.stashEntry.index, reinstateIndexCheck.checked)
        } else if (action === "pop") {
            result = root.stashController.pop(root.stashEntry.index, reinstateIndexCheck.checked)
        } else if (action === "remove") {
            result = root.stashController.remove(root.stashEntry.index)
        }

        if (result.success) {
            // optional: emit signal or callback to parent to refresh list
        }
    }

    function statusLabel(fileOrDelta) {
        switch (fileOrDelta) {
            case GitFileStatus.ADDED:
                return "A"

            case GitFileStatus.DELETED:
                return "D"

            case GitFileStatus.MODIFIED:
                return "M"

            case GitFileStatus.RENAMED:
                return "R"

            default:
                return "?"
        }
    }

    function statusColor(deltaStatus) {
        switch (deltaStatus) {
            case GitFileStatus.ADDED:
                return Style.colors.conflictStatusAddedColor

            case GitFileStatus.DELETED:
                return Style.colors.conflictStatusConflictColor

            case GitFileStatus.MODIFIED:
                return Style.colors.conflictStatusModifiedColor

            default:
                return Style.colors.mutedText
        }
    }
}
