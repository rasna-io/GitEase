import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * InitNewTab
 * Create a new repository. Exposes `location` and `name`. (Branch, license and the extra-files
 * options are UI only.)
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property AppModel appModel
    property string   location: ""
    property string   name: ""

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: col.implicitHeight + 32

    /* Functions
     * ****************************************************************************************/
    function reset() {
        root.location = ""
        root.name = ""
        locationField.text = ""
        nameField.text = ""
    }

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        id: col
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 16
        spacing: 6

        Text {
            text: "Create a new Git repository"
            font.family: Style.fontTypes.inter
            font.weight: Font.DemiBold
            font.pixelSize: 13
            color: Style.colors.foreground
            Layout.bottomMargin: 2
        }

        RepoSectionLabel {
            text: "Location"
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            RepoTextField {
                id: locationField
                placeholderText: "C:/Users/Username/Documents"
                onTextChanged: root.location = text
            }

            RepoBrowseButton {
                onClicked: folderDialog.open()
            }
        }

        RepoSectionLabel {
            text: "Name"
            Layout.topMargin: 4
        }

        RepoTextField {
            id: nameField
            placeholderText: "my-project"
            onTextChanged: root.name = text
        }

        Text {
            visible: root.location !== "" && root.name !== ""
            text: "Will create: " + root.location.replace(/[\/\\]+$/, "") + "/" + root.name
            font.family: Style.fontTypes.inter
            font.pixelSize: 10
            color: Style.colors.mutedText
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                RepoSectionLabel {
                    text: "Initial branch"
                }

                ComboBox {
                    Layout.fillWidth: true
                    font.pixelSize: 12
                    model: ["main", "master"]
                    Material.background: Style.colors.controlBackground
                    Material.foreground: Style.colors.foreground
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6
                RepoSectionLabel {
                    text: "License"
                }

                ComboBox {
                    Layout.fillWidth: true
                    font.pixelSize: 12
                    model: ["MIT", "Apache-2.0", "GPL-3.0", "None"]
                    Material.background: Style.colors.controlBackground
                    Material.foreground: Style.colors.foreground
                }
            }
        }

        ButtonGroup {
            id: initGroup
        }

        Repeater {
            model: ["Empty repository", "Add .gitignore", "Add README.md"]

            RepoRadio {
                Layout.fillWidth: true
                Layout.topMargin: index === 0 ? 6 : 0
                text: modelData
                checked: index === 0
                ButtonGroup.group: initGroup
            }
        }
    }

    FolderDialog {
        id: folderDialog
        title: "Select Location"
        currentFolder: root.appModel?.appSettings?.generalSettings?.defaultPath ?? ""

        onAccepted: {
            if (folderDialog.selectedFolder)
                locationField.text = root.appModel.fileIO.pathNormalizer(folderDialog.selectedFolder.toString())
        }
    }
}
