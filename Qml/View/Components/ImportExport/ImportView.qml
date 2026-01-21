import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ImportView
 * Import bundle view
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property BranchController   branchController:     null
    property BundleController   bundleController:     null
    property string             selectedFile:         ""

    /* Object Properties
     * ****************************************************************************************/
    anchors.fill: parent

    /* Children
     * ****************************************************************************************/
    FileDialog {
        id: fileDialog
        title: "Select Project Archive"
        nameFilters: ["Archive files (*.zip *.tar.gz)"]
        onAccepted: root.selectedFile = selectedFile.toString().replace(new RegExp("^file://+"), "")
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Project Archive"
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
                    color: root.selectedFile === "" ? Style.colors.placeholderText : Style.colors.secondaryText
                    text: "Select .zip or .tar.gz file..."
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

                    onClicked: fileDialog.open()
                }
            }
        }

        // Hint row
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 50
            radius: 5
            color: Style.colors.secondaryBackground
            border.width: 1
            border.color: Style.colors.secondaryBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Import will extract and restore the project structure, branches, and commit history from the selected archive."
                        wrapMode: Text.WordWrap
                        font.pixelSize: 10
                        color: Style.colors.mutedText
                        font.family: Style.fontTypes.roboto
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        Button {
            Layout.fillWidth: true
            implicitHeight: 44
            enabled: root.selectedFile !== ""

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
                        text: Style.icons.upload
                        font.family: Style.fontTypes.font6Pro
                        font.pixelSize: 12
                        color: Style.colors.secondaryForeground
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Import Project"
                        color: Style.colors.secondaryForeground
                        font.pixelSize: 13
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // TODO
            onClicked: console.log("Import:", root.selectedFile)
        }
    }

    onSelectedFileChanged: fileLabel.text = root.selectedFile

    /* Functions
     * ****************************************************************************************/
}
