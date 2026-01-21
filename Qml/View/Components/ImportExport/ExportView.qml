import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ExportView
 * Export bundle view
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property BranchController   branchController:     null
    property string             selectedFolder:       ""
    property var                branches:             []

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/
    FolderDialog {
        id: folderDialog
        title: "Select Directory"
        onAccepted: root.selectedFolder = folderDialog.selectedFolder.toString().replace(new RegExp("^file://+"), "")
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Target Branch"
                font.pixelSize: 12
                color: Style.colors.mutedText
            }

            ComboBox {
                id: branchesCombo
                Layout.fillWidth: true
                model: root.branches
                minHeight: 26
                focusBorderWidth: 1
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 12

                placeholderText: "Select branch"

                Material.background: Style.colors.primaryBackground
                Material.foreground: Style.colors.secondaryText

                background: Rectangle {
                    radius: 5
                    color: branchesCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                onActivated: function(index) {
                    // TODO
                    console.log("Selecte Branch : ", root.branches[index])
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Base Branch"
                font.pixelSize: 12
                color: Style.colors.mutedText
            }

            ComboBox {
                id: baseBranchCombo
                Layout.fillWidth: true
                model: root.branches
                minHeight: 26
                focusBorderWidth: 1
                font.family: Style.fontTypes.roboto
                font.weight: 400
                font.pixelSize: 12

                placeholderText: "Select Base"

                Material.background: Style.colors.primaryBackground
                Material.foreground: Style.colors.secondaryText

                background: Rectangle {
                    radius: 5
                    color: baseBranchCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                onActivated: function(index) {
                    // TODO
                    console.log("Selecte Base Branch : ", root.branches[index])
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Output Directory"
                font.pixelSize: 12
                color: Style.colors.mutedText
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 20
                spacing: 8

                Label {
                    id: fileLabel
                    Layout.fillWidth: true
                    Layout.leftMargin: 10
                    Layout.rightMargin: 10
                    Layout.preferredHeight: 20
                    elide: Text.ElideRight
                    color: root.selectedFolder === "" ? Style.colors.placeholderText : Style.colors.secondaryText
                    text: "Select Directory..."
                }

                Button {
                    id: fileButton

                    implicitWidth: 28
                    implicitHeight:28

                    text: Style.icons.folder
                    font.family: Style.fontTypes.font6Pro
                    font.pixelSize: 14

                    topInset: 0
                    bottomInset: 0

                    flat: true
                    Material.elevation: 0

                    background: Rectangle {
                        radius: 6
                        color: fileButton.hovered ? Style.colors.accentHover : "transparent"
                        border.width: 1
                        border.color: Style.colors.primaryBorder
                    }

                    contentItem: Text {
                        text: fileButton.text
                        font: fileButton.font
                        color: fileButton.hovered ? Style.colors.secondaryForeground : Style.colors.secondaryText
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    onClicked: folderDialog.open()
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Button {
            Layout.fillWidth: true
            implicitHeight: 44
            enabled: root.selectedFolder !== ""

            background: Rectangle {
                radius: 8
                color: enabled ? Style.colors.accent : Style.colors.disabledButton
            }

            contentItem: Item {
                anchors.fill: parent

                Row {
                    spacing: 10
                    anchors.centerIn: parent

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Style.icons.download
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 12
                        color: Style.colors.secondaryForeground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Export Project"
                        color: Style.colors.secondaryForeground
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // TODO
            onClicked: console.log("Export:", root.selectedFolder)
        }
    }

    onSelectedFolderChanged: fileLabel.text = root.selectedFolder

    onBranchControllerChanged: {
        if(!branchController)
            return

        let allBranches = branchController.getBranches()
        let branchNames = []

        for(let i = 0 ; i < allBranches.length; i++){
            branchNames.push(allBranches[i].name)
        }

        root.branches = branchNames
    }

    /* Functions
     * ****************************************************************************************/
}
