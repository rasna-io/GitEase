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
    property NotificationController notificationController: null

    /* Object Properties (sized by parent layout when used in StackLayout)
     * ****************************************************************************************/
    implicitHeight: mainLayout.implicitHeight

    /* Children
     * ****************************************************************************************/
    FileDialog {
        id: fileDialog
        title: "Select bundle"
        nameFilters: ["Bundle files (*.bundle)"]
        onAccepted: root.selectedFile = selectedFile.toString().replace(new RegExp("^file://+"), "")
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 6

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Bundle"
                font.pixelSize: Style.appFont.captionPt
                color: Style.colors.mutedText
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.dp(25)
                spacing: Style.dp(8)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Style.dp(25)
                    radius: Style.dp(5)
                    color: Style.colors.secondaryBackground
                    ScrollingText {
                        id: fileLabel
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Style.dp(15)
                        anchors.left: parent.left
                        anchors.right: parent.right
                        color: root.selectedFile === "" ? Style.colors.placeholderText : Style.colors.secondaryText
                        text: root.selectedFile !== "" ? root.selectedFile : "Select .bundle file..."
                    }
                }

                IconButton {
                    id: fileButton

                    implicitWidth: Style.dp(25)
                    implicitHeight: Style.dp(25)

                    topInset: 0
                    bottomInset: 0

                    display: IconButton.IconOnly
                    icon.name: Style.icons.folder
                    icon.width: Style.appFont.smallPt
                    icon.height: Style.appFont.smallPt
                    icon.color: fileButton.hovered ? Style.colors.secondaryForeground : Style.colors.secondaryText
                    tooltip: "Select bundle"

                    background: Rectangle {
                        radius: 6
                        color: fileButton.hovered ? Style.colors.accentHover : "transparent"
                        border.width: 1
                        border.color: Style.colors.primaryBorder
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
                font.pixelSize: Style.appFont.captionPt
                color: Style.colors.mutedText
            }

            TextField {
                id: branchTXF
                Layout.fillWidth: true
                Layout.preferredHeight: Style.dp(25)
                background: Rectangle {
                    radius: Style.dp(5)
                    color: Style.colors.secondaryBackground
                }
            }
        }

        // Hint row
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(32)
            radius: 4
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
                        anchors.leftMargin: 8
                        text: "Import will extract and restore the project structure, branches, and commit history from the selected archive."
                        wrapMode: Text.WordWrap
                        font.pixelSize: Style.appFont.captionPt
                        color: Style.colors.mutedText
                        font.family: Style.fontTypes.inter
                    }
                }
            }
        }

        IconButton {
            id: importButton
            Layout.fillWidth: true
            implicitHeight: Style.dp(25)
            enabled: root.selectedFile !== "" && branchTXF.text !== ""

            display: IconButton.TextBesideIcon
            icon.name: Style.icons.upload
            icon.width: Style.appFont.smallPt
            icon.height: Style.appFont.smallPt
            icon.color: Style.colors.secondaryForeground
            text: "Import"
            font.pixelSize: Style.appFont.mediumPt

            background: Rectangle {
                radius: Style.dp(4)
                color: importButton.enabled ? Style.colors.accent : Style.colors.disabledButton
            }

            onClicked: {
                let res = root.bundleController.unbundle(root.selectedFile)
                if (res.success && root.notificationController) {
                    root.notificationController.success("Bundle imported successfully", "Import", 3000)
                    root.branchController.createBranch(res.data.SHA, branchTXF.text)
                } else if (!res.success && root.notificationController) {
                    root.notificationController.error(res.errorMessage || "Failed to import bundle", "Import Error", 5000)
                }
            }
        }
    }

    Connections {
        target: root.branchController

        function onCurrentRepoChanged() {
            root.selectedFile = ""
            branchTXF.text = ""
        }
    }

    onSelectedFileChanged: fileLabel.text = root.selectedFile

    /* Functions
     * ****************************************************************************************/
}
