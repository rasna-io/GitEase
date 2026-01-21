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
        title: "Select bundle"
        nameFilters: ["Bundle files (*.bundle)"]
        onAccepted: root.selectedFile = selectedFile.toString().replace(new RegExp("^file://+"), "")
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 10

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Bundle"
                font.pixelSize: 12
                color: Style.colors.mutedText
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    radius: 5
                    color: Style.colors.secondaryBackground
                    Text {
                        id: fileLabel
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 15
                        anchors.left: parent.left
                        anchors.right: parent.right
                        elide: Text.ElideLeft
                        color: root.selectedFile === "" ? Style.colors.placeholderText : Style.colors.secondaryText
                        text: root.selectedFile !== "" ? root.selectedFile : "Select .bundle file..."
                    }
                }

                Button {
                    id: fileButton

                    implicitWidth: 40
                    implicitHeight: 40

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

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Branch"
                font.pixelSize: 12
                color: Style.colors.mutedText
            }

            TextField {
                id: txf
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                background: Rectangle {
                    radius: 5
                    color: Style.colors.secondaryBackground
                }
            }
        }

        // Hint row
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 65
            radius: 5
            color: Style.colors.secondaryBackground
            border.width: 1
            border.color: Style.colors.secondaryBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4

                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    Text {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Import will extract and restore the project structure, branches, and commit history from the selected archive."
                        wrapMode: Text.WordWrap
                        font.pixelSize: 11
                        color: Style.colors.mutedText
                        font.family: Style.fontTypes.roboto
                    }
                }
            }
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
                        text: "Import"
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
