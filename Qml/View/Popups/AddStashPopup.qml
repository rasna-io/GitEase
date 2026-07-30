import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * AddStashPopup
 * ************************************************************************************************/

IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property StashController        stashController:        null
    property NotificationController notificationController: null
    property StatusController       statusController:       null

    property var    stashFiles:       []
    property var    stashDiffData:    []
    property string selectedFilePath: ""

    readonly property bool canAccept: root.stashFiles.length > 0 && root.stashController !== null

    readonly property string headerMeta: {
        if (root.stashFiles.length === 0)
            return qsTr("Nothing to shelve — the working tree is clean")

        let parts = [root.stashFiles.length === 1 ? qsTr("1 file") : qsTr("%1 files").arg(root.stashFiles.length)]

        if (root.stagedCount > 0)
            parts.push(qsTr("%1 staged").arg(root.stagedCount))
        if (root.untrackedCount > 0)
            parts.push(qsTr("%1 untracked").arg(root.untrackedCount))

        return parts.join("  •  ")
    }

    readonly property int stagedCount:    root.stashFiles.filter(file => file.isStaged).length
    readonly property int untrackedCount: root.stashFiles.filter(file => file.isUntracked).length

    readonly property var fileEntries: root.stashFiles.map(file => ({
        path:        file.path,
        statusText:  root.statusLabel(file),
        statusColor: root.statusColor(file),
        additions:   file.additionsCount || 0,
        deletions:   file.deletionsCount || 0
    }))

    /* Object Properties
     * ****************************************************************************************/
    width: 800
    height: 650
    padding: 0

    onOpened: root.loadFiles()

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

                title:    qsTr("Create Stash")
                metaText: root.headerMeta

                onCloseRequested: root.closePopUp()
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 6
                Layout.bottomMargin: 6
                spacing: 10

                TextField {
                    id: stashMessageField
                    Layout.fillWidth: true

                    placeholderText: "Stash message (optional)"

                    minHeight: Style.dp(26)
                    topPadding: 4
                    bottomPadding: 4
                    borderRadius: 4
                    baseFontSize: 12
                    backgroundColor: Style.colors.controlBackground
                    borderColor: Style.colors.controlBorder
                    focusBorderColor: Style.colors.accent
                    placeholderTextColor: Style.colors.placeholderText
                }

                CheckBox {
                    id: keepIndexCheckBox
                    Layout.alignment: Qt.AlignVCenter
                    padding: 0
                    checked: true
                    text: "Keep staged changes in index"

                    font.family: Style.fontTypes.inter
                    font.pixelSize: Style.appFont.smallPt

                    Material.accent: Style.colors.accent
                    Material.foreground: Style.colors.foreground

                    palette {
                        text: Style.colors.foreground
                    }
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
                    sectionTitle: "CHANGES TO STASH"
                    emptyText:    "No uncommitted changes"

                    onFileSelected: (path) => root.selectPath(path)
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

                //! The command this window is about to run, kept in sync with GitStash::save()
                Text {
                    Layout.fillWidth: true
                    text: {
                        let command = "git stash push"
                        if (keepIndexCheckBox.checked)
                            command += " --keep-index"

                        let message = stashMessageField.text.trim()
                        if (message.length > 0)
                            command += ` -m "${message}"`

                        return command
                    }
                    color: Style.colors.conflictSectionLabel
                    elide: Text.ElideRight
                    font.family: Style.fontTypes.jetBrainsMono
                    font.pixelSize: Style.appFont.captionPt
                }

                ConflictPillButton {
                    Layout.preferredHeight: Style.dp(30)
                    text: "Cancel"
                    accentColor: Style.colors.mutedText
                    tooltip: "Close without shelving anything"
                    onClicked: root.closePopUp()
                }

                ConflictPillButton {
                    Layout.preferredHeight: Style.dp(30)
                    text: "Create stash"
                    trailingText: Style.icons.arrowRight
                    accentColor: Style.colors.accent
                    prominent: root.canAccept
                    actionEnabled: root.canAccept
                    tooltip: root.canAccept ? "Shelve these changes and clean the working tree"
                                            : "There are no uncommitted changes to stash"
                    onClicked: root.createStash()
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function createStash() {
        if (!root.canAccept)
            return

        let result = root.stashController.save(stashMessageField.text.trim(), keepIndexCheckBox.checked)
        if (result.success) {
            root.closePopUp()
            return
        }

        if (root.notificationController) {
            root.notificationController.error(result.errorMessage || "Failed to create stash",
                                              "Stash Error", 5000)
        }
    }

    function loadFiles() {
        root.stashFiles = []
        root.stashDiffData = []
        root.selectedFilePath = ""

        if (!root.statusController)
            return

        let res = root.statusController.status()
        if (!res.success)
            return

        let filtered = []
        res.data.forEach((file) => {
            if (file.isStaged || file.isUnstaged || file.isUntracked) {
                filtered.push(file)
            }
        })
        root.stashFiles = filtered

        if (root.stashFiles.length > 0) {
            root.selectFile(root.stashFiles[0])
        }
    }

    function selectPath(filePath) {
        for (let i = 0; i < root.stashFiles.length; ++i) {
            if (root.stashFiles[i].path === filePath) {
                root.selectFile(root.stashFiles[i])
                return
            }
        }
    }

    function selectFile(file) {
        root.selectedFilePath = file.path
        root.stashDiffData = []

        if (!root.statusController || !root.selectedFilePath)
            return

        let res = root.statusController.getDiffView(root.selectedFilePath, !!file.isStaged)

        if (res.success) {
            root.stashDiffData = res.data.lines  // Use the lines for DiffView
        }
    }

    function closePopUp() {
        stashMessageField.text = ""
        keepIndexCheckBox.checked = true
        root.selectedFilePath = ""
        root.stashDiffData = []
        root.stashFiles = []
        root.close()
    }

    function statusLabel(file) {
        if (file.isStaged)
            return "S"
        if (file.isUntracked)
            return "U"
        return "M"
    }

    function statusColor(file) {
        if (file.isStaged)
            return Style.colors.conflictStatusAddedColor
        if (file.isUntracked)
            return Style.colors.mutedText
        return Style.colors.conflictStatusModifiedColor
    }
}
