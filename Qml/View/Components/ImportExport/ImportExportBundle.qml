import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style_Impl
import GitEase_Style
import GitEase

/*! ***********************************************************************************************
 * ImportExportBundle
 * Import and Export git bundle
 * ************************************************************************************************/

Rectangle {
    id: root

    property BranchController branchController: null
    property BundleController bundleController: null

    /* Property Declarations
     * ****************************************************************************************/
    property int currentIndex: 0

    /* Object Properties
     * ****************************************************************************************/
    color: Style.colors.primaryBackground
    radius: 7
    border.width: 1
    border.color: Style.colors.primaryBorder

    /* Signals
     * ****************************************************************************************/

    /* Children
     * ****************************************************************************************/
    ButtonGroup {
        id: headerButtonGroup
        exclusive: true
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 16

        // Header
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 20
            spacing: 10

            Label {
                text: Style.icons.arowLeftRight
                color: Style.colors.accent
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: 15
            }

            Label {
                text: "Export / Import Project"
                color: Style.colors.foreground
                font.family: Style.fontTypes.roboto
                font.pixelSize: 13
                font.bold: true
            }
        }

        // View Control
        Rectangle {
            id: viewControl
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 20
            color: Style.colors.cardBackground

            RowLayout {
                anchors.fill: parent
                spacing: 4
                anchors.margins: 2

                Button {
                    id: exportBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    topInset: 0
                    bottomInset:0
                    verticalPadding: 6

                    checkable: true
                    checked: root.currentIndex === 0
                    ButtonGroup.group: headerButtonGroup

                    onClicked: root.currentIndex = 0

                    contentItem: Row {
                        spacing: 8
                        anchors.centerIn: parent

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Style.icons.download
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: 12
                            color: Style.colors.foreground
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Export"
                            font.pixelSize: Style.appFont.h3Pt
                            color: Style.colors.foreground
                        }
                    }

                    background: Rectangle {
                        radius: viewControl.radius
                        color: exportBtn.checked ? Style.colors.primaryBackground : "transparent"
                    }
                }

                Button {
                    id: importBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    topInset: 0
                    bottomInset:0
                    verticalPadding: 6

                    checkable: true
                    checked: root.currentIndex === 1
                    ButtonGroup.group: headerButtonGroup

                    onClicked: root.currentIndex = 1

                    contentItem: Row {
                        spacing: 8
                        anchors.centerIn: parent

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Style.icons.upload
                            font.family: Style.fontTypes.font6Pro
                            font.pixelSize: 12
                            color: Style.colors.foreground
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Import"
                            font.pixelSize: Style.appFont.h3Pt
                            color: Style.colors.foreground
                        }
                    }

                    background: Rectangle {
                        radius: viewControl.radius
                        color: importBtn.checked ? Style.colors.primaryBackground : "transparent"
                    }
                }
            }
        }

        // Content Area
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentIndex

            ExportView {
                branchController: root.branchController
                bundleController: root.bundleController
            }

            ImportView {
                branchController: root.branchController
                bundleController: root.bundleController
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
}
