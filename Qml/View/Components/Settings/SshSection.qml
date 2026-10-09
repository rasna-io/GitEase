import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SshSection
 * SSH key-management panel used inside the Settings → SSH tab.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    required property SshKeyController       sshKeyController

    property          NotificationController notificationController:   null

    property          UserProfile            currentUserProfile:       null


    // Items the SSH guid
    readonly property Item generateButton: generateBtn
    readonly property Item emptyStateItem: emptyState
    readonly property Item keyListItem:    listView
    readonly property Item firstKeyCard:   listView.itemAtIndex(0)
    readonly property Item firstKeyCopy:   firstKeyCard ? firstKeyCard.copyButtonItem : null
    readonly property Item firstKeyChips:  firstKeyCard ? firstKeyCard.chipsItem : null

    /* Object Properties
     * ****************************************************************************************/

    implicitHeight: content.implicitHeight

    // Hidden TextEdit used solely for clipboard copy
    TextEdit {
        id: clipboardHelper
        visible: false
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: content
        anchors.fill: parent
        spacing: 4


        ButtonItem {
            id: generateBtn
            Layout.fillWidth: true
            title: "SSH Key"
            buttonWidth: 160
            description: "Generate and manage SSH keys to authenticate with GitHub, GitLab and other Git hosts. Choose where each key is used with the “Use for” chips: GitHub, GitLab, or all other hosts. Upload each public key to its host. Keys already in ~/.ssh are listed automatically."
            enabled: !root.sshKeyController.isGenerating
            buttonTitle: {
                if (root.sshKeyController.isGenerating)
                    return "Generating …"
                return "Generate New Key"
            }
            busy: root.sshKeyController.isGenerating
            onClicked: namePopup.openForGenerate()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.bottomMargin: 6
            Layout.preferredHeight: 2
            color: Style.colors.primaryBorder
        }

        ButtonItem {
            id: importKeyItem
            Layout.fillWidth: true
            title: "Import Key"
            buttonWidth: 160
            description: "Copy an existing private key into ~/.ssh. Passphrase-protected keys need an ssh-agent."
            buttonTitle: "Import …"
            onClicked: importFileDialog.open()
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.topMargin: 6
            Layout.preferredHeight: 2
            color: Style.colors.primaryBorder
        }

        // Empty state: explain what SSH keys are for and what to do next
        Rectangle {
            id: emptyState
            visible: root.sshKeyController.allKeys.length === 0
            Layout.fillWidth: true
            Layout.topMargin: 10
            implicitHeight: emptyCol.implicitHeight + 24
            radius: 8
            color: Style.colors.controlBackground
            border.color: Style.colors.controlBorder
            border.width: 1

            ColumnLayout {
                id: emptyCol
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    margins: 12
                }
                spacing: 8

                Text {
                    text: "No SSH keys found"
                    font.pointSize: Style.appFont.h4Pt
                    font.bold: true
                    color: Style.colors.foreground
                    Layout.fillWidth: true
                }

                Text {
                    text: "SSH keys let you sign in to GitHub, GitLab and other Git hosts without entering credentials every time."
                    font.pointSize: Style.appFont.defaultPt
                    color: Style.colors.mutedText
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: "1. Click “Generate New Key” above.\n"
                        + "2. Copy the public key with the copy button.\n"
                        + "3. Paste it into your Git host:"
                    font.pointSize: Style.appFont.defaultPt
                    color: Style.colors.foreground
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Text {
                    text: "<a href=\"https://github.com/settings/ssh/new\">Add key on GitHub</a>"
                        + " &nbsp;·&nbsp; "
                        + "<a href=\"https://gitlab.com/-/user_settings/ssh_keys\">Add key on GitLab</a>"
                    textFormat: Text.RichText
                    linkColor: Style.colors.accent
                    font.pointSize: Style.appFont.defaultPt
                    Layout.fillWidth: true
                    onLinkActivated: (link) => Qt.openUrlExternally(link)

                    HoverHandler {
                        cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                    }
                }

                Text {
                    text: "Self-hosted GitLab? Use Settings → SSH Keys on your instance."
                    font.pointSize: Style.appFont.secondaryPt
                    color: Style.colors.mutedText
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }
            }
        }

        RowLayout {
            visible: root.sshKeyController.allKeys.length > 0
            Layout.fillWidth: true
            Layout.topMargin: 14
            Layout.bottomMargin: 4
            spacing: 8

            Text {
                text: "Available Keys"
                font.pointSize: Style.appFont.h4Pt
                color: Style.colors.foreground
            }

            Rectangle {
                implicitWidth: countText.implicitWidth + 12
                implicitHeight: countText.implicitHeight + 4
                radius: height / 2
                color: Style.colors.controlBackground
                border.color: Style.colors.controlBorder
                border.width: 1

                Text {
                    id: countText
                    anchors.centerIn: parent
                    text: root.sshKeyController.allKeys.length
                    font.pointSize: Style.appFont.secondaryPt
                    color: Style.colors.mutedText
                }
            }

            Item { Layout.fillWidth: true }
        }

        Item {
            Layout.fillHeight: listView.count > 0 ? false : true
        }

        ListView {
            id: listView
            visible: root.sshKeyController.allKeys.length > 0
            Layout.fillWidth: true
            Layout.fillHeight: true
            model: root.sshKeyController.allKeys
            spacing: 10
            clip: true
            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }

            delegate: SshKeyCard {
                required property var modelData

                width: ListView.view.width - 16
                keyData: modelData

                onRenameRequested: (oldName, newName) => root.doRenameKey(oldName, newName)
                onCopyRequested: (publicKey) => root.doCopyPublicKey(publicKey)
                onAssignRequested: (provider, label, keyName, currentlyAssigned) =>
                                   root.doToggleProvider(provider, label, keyName, currentlyAssigned)
                onExportRequested: (keyName) => {
                    exportPopup.targetKeyName = keyName
                    exportPopup.open()
                }
                onDeleteRequested: (keyName) => {
                    deletePopup.targetKeyName = keyName
                    deletePopup.open()
                }
            }
        }
    }

    FileDialog {
        id: importFileDialog
        title: "Select the private key file (not the .pub)"
        nameFilters: ["All files (*)"]
        onAccepted: namePopup.openForImport(selectedFile.toString())
    }

    FolderDialog {
        id: exportFolderDialog
        title: "Choose export folder"
        onAccepted: root.doExportKey(exportPopup.targetKeyName,
                                     selectedFolder.toString(),
                                     exportPopup.includePrivate)
    }

    SshKeyNamePopup {
        id: namePopup
        sshKeyController: root.sshKeyController
        onGenerateRequested: (keyName) => root.doGenerateKey(root.currentUserProfile?.email ?? "", keyName)
        onImportRequested: (source, keyName) => root.doImportKey(source, keyName)
    }

    SshKeyExportPopup {
        id: exportPopup
        onChooseFolderRequested: exportFolderDialog.open()
    }

    SshKeyDeletePopup {
        id: deletePopup
        onDeleteConfirmed: (keyName) => root.doDeleteKey(keyName)
    }

    /* Functions
     * ****************************************************************************************/
    function doGenerateKey(keyComment, keyName) {
        const result = root.sshKeyController.generateKey(keyComment, keyName)
        if (result.success) {
            if (root.notificationController)
                root.notificationController.success(
                    "SSH key generated. Copy the public key and add it under Settings → SSH Keys on GitHub or GitLab.",
                    "SSH Key", 5000)
        } else {
            if (root.notificationController)
                root.notificationController.error(
                    result.errorMessage || "Failed to generate SSH key",
                    "SSH Key Error", 6000)
        }
    }

    function doCopyPublicKey(publicKey) {
        clipboardHelper.text = publicKey
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        if (root.notificationController)
            root.notificationController.success("Public key copied to clipboard", "SSH Key", 2500)
    }

    function doToggleProvider(provider, label, keyName, currentlyAssigned) {
        if (provider === "") {
            if (!currentlyAssigned)
                doSetActiveKey(keyName)
            return
        }
        const result = root.sshKeyController.setProviderKey(provider, currentlyAssigned ? "" : keyName)
        if (result.success) {
            if (root.notificationController)
                root.notificationController.success(
                    currentlyAssigned
                        ? label + " remotes will use the default key again."
                        : "\"" + keyName + "\" will be used for " + label + " remotes.",
                    "SSH Key", 3000)
        } else if (root.notificationController) {
            root.notificationController.error(
                result.errorMessage || "Failed to update key assignment", "SSH Key Error", 5000)
        }
    }

    function doImportKey(source, keyName) {
        const result = root.sshKeyController.importKey(source, keyName)
        if (!root.notificationController)
            return
        if (!result.success) {
            root.notificationController.error(
                result.errorMessage || "Failed to import SSH key", "SSH Key Error", 6000)
            return
        }
        if (result.data && result.data.encrypted) {
            root.notificationController.warning(
                "Key imported, but it is passphrase-protected. GitEase can only use it through a running ssh-agent.",
                "SSH Key", 8000)
        } else {
            root.notificationController.success(
                "SSH key imported. Add its public key to GitHub or GitLab if you haven't already.",
                "SSH Key", 5000)
        }
    }

    function doExportKey(keyName, folderUrl, includePrivate) {
        const result = root.sshKeyController.exportKey(keyName, folderUrl, includePrivate)
        if (!root.notificationController)
            return
        if (result.success) {
            root.notificationController.success(
                (includePrivate ? "Key pair" : "Public key") + " exported to " + result.data,
                "SSH Key", 5000)
        } else {
            root.notificationController.error(
                result.errorMessage || "Failed to export SSH key", "SSH Key Error", 6000)
        }
    }

    function doSetActiveKey(keyName) {
        const result = root.sshKeyController.setActiveKey(keyName)
        if (result.success) {
            if (root.notificationController)
                root.notificationController.success(
                    "\"" + keyName + "\" will be used for all other SSH remotes.",
                    "SSH Key", 3000)
        } else if (root.notificationController) {
            root.notificationController.error(
                result.errorMessage || "Failed to select SSH key", "SSH Key Error", 5000)
        }
    }

    function doRenameKey(oldName, newName) {
        const result = root.sshKeyController.renameKey(oldName, newName)
        if (result.success) {
            if (root.notificationController)
                root.notificationController.success("SSH key renamed.", "SSH Key", 2500)
        } else {
            if (root.notificationController)
                root.notificationController.error(
                    result.errorMessage || "Failed to rename SSH key",
                    "SSH Key Error", 5000)
        }
    }

    function doDeleteKey(keyName) {
        const result = root.sshKeyController.deleteKeyByName(keyName)
        if (result.success) {
            if (root.notificationController)
                root.notificationController.success("SSH key deleted.", "SSH Key", 3000)
        } else {
            if (root.notificationController)
                root.notificationController.error(
                    result.errorMessage || "Failed to delete SSH key",
                    "SSH Key Error", 5000)
        }
    }
}
