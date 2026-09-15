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
                font.pixelSize: Style.appFont.smallPt
                color: Style.colors.utilitiesFieldLabel
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: Style.dp(25)
                spacing: Style.dp(8)

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Style.dp(25)
                    radius: Style.dp(5)
                    color: Style.colors.utilitiesInputBackground
                    border.width: 1
                    border.color: Style.colors.utilitiesInputBorder

                    ScrollingText {
                        id: fileLabel
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: Style.dp(15)
                        anchors.left: parent.left
                        anchors.right: parent.right
                        color: root.selectedFile === "" ? Style.colors.utilitiesInputPlaceholder
                                                       : Style.colors.utilitiesInputText
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
                    icon.color: fileButton.hovered ? Style.colors.utilitiesPickerButtonIconHover
                                                   : Style.colors.utilitiesPickerButtonIcon
                    tooltip: "Select bundle"

                    background: Rectangle {
                        radius: 6
                        color: fileButton.hovered ? Style.colors.utilitiesPickerButtonHoverBackground
                                                  : Style.colors.utilitiesPickerButtonBackground
                        border.width: 1
                        border.color: Style.colors.utilitiesPickerButtonBorder
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
                font.pixelSize: Style.appFont.smallPt
                color: Style.colors.utilitiesFieldLabel
            }

            TextField {
                id: branchTXF
                Layout.fillWidth: true
                Layout.preferredHeight: Style.dp(25)
                color: Style.colors.utilitiesInputText
                placeholderTextColor: Style.colors.utilitiesInputPlaceholder
                background: Rectangle {
                    radius: Style.dp(5)
                    color: Style.colors.utilitiesInputBackground
                    border.width: 1
                    border.color: branchTXF.activeFocus ? Style.colors.utilitiesInputBorderFocus
                                                        : Style.colors.utilitiesInputBorder
                }
            }
        }

        // Hint row
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(46)
            radius: 4
            color: Style.colors.utilitiesSurfaceBackground
            border.width: 1
            border.color: Style.colors.utilitiesSurfaceBorder

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
                        font.pixelSize: Style.appFont.smallPt
                        color: Style.colors.utilitiesHintText
                        font.family: Style.fontTypes.inter
                    }
                }
            }
        }

        DashedButton {
            id: importButton
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(5)
            enabled: root.selectedFile !== "" && branchTXF.text !== ""

            iconText: Style.icons.upload
            text: "Import"

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
