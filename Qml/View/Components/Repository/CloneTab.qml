import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * CloneTab
 * Clone URL, auth choice, destination and options. Exposes `url`, `toPath` and `auth`.
 * (Auth, folder name and clone depth are UI only.)
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel appModel
    property string   url: ""
    property string   toPath: ""
    property int      auth: 0

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: Math.min(col.implicitHeight + 32, 520)

    /* Functions
     * ****************************************************************************************/
    function reset() {
        root.url = ""
        root.toPath = ""
        root.auth = 0
        urlField.text = ""
        toField.text = ""
        folderField.text = ""
    }

    // Extract the host from an https:// or git@host: URL (best-effort, for the validation line).
    function urlHost(u) {
        var m = u.match(/^[a-zA-Z][a-zA-Z0-9+.-]*:\/\/([^\/]+)/)
        if (m)
            return m[1]
        m = u.match(/@([^:\/]+)[:\/]/)
        if (m)
            return m[1]
        return ""
    }

    /* Children
     * ****************************************************************************************/
    ScrollView {
        id: scroll
        anchors.fill: parent
        anchors.margins: 16
        clip: true
        contentWidth: availableWidth
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: col
            width: scroll.availableWidth
            spacing: 6

            RepoSectionLabel {
                text: "Repository URL"
            }

            RepoTextField {
                id: urlField
                placeholderText: "https://github.com/username/repository.git"
                onTextChanged: root.url = text
            }

            RepoValidationLine {
                Layout.fillWidth: true
                visible: root.urlHost(root.url) !== ""
                strong: root.urlHost(root.url)
                muted: "· reachable"
            }

            RepoSectionLabel {
                text: "Auth"
                Layout.topMargin: 8
            }

            ButtonGroup {
                id: authGroup
            }

            Repeater {
                model: [
                    { label: "None (public repo)",  value: 0 },
                    { label: "SSH key",             value: 1 },
                    { label: "Username / Password", value: 2 }
                ]

                RepoRadio {
                    Layout.fillWidth: true
                    text: modelData.label
                    checked: root.auth === modelData.value
                    ButtonGroup.group: authGroup
                    onClicked: root.auth = modelData.value
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 16

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    RepoSectionLabel {
                        text: "Clone to"
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RepoTextField {
                            id: toField
                            placeholderText: "C:/Users/Username/Documents/Projects"
                            onTextChanged: root.toPath = text
                        }

                        RepoBrowseButton {
                            onClicked: folderDialog.open()
                        }
                    }
                }

                ColumnLayout {
                    Layout.preferredWidth: 140
                    spacing: 6

                    RepoSectionLabel {
                        text: "Folder name"
                    }

                    RepoTextField {
                        id: folderField
                        placeholderText: "repository"
                    }
                }
            }

            RepoSectionLabel {
                text: "Clone depth"
                Layout.topMargin: 8
            }

            ComboBox {
                Layout.fillWidth: true
                font.pixelSize: 12
                model: ["Full history", "Shallow (depth 1)", "Depth 50"]
                Material.background: Style.colors.controlBackground
                Material.foreground: Style.colors.foreground
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Select Clone Destination"
        currentFolder: root.appModel?.appSettings?.generalSettings?.defaultPath ?? ""

        onAccepted: {
            if (folderDialog.selectedFolder)
                toField.text = root.appModel.fileIO.pathNormalizer(folderDialog.selectedFolder.toString())
        }
    }
}
