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

UtilitiesCard {
    id: root


    /* Property Declarations
     * ****************************************************************************************/
    property int currentIndex: 0

    property BranchController branchController: null

    property BundleController bundleController: null

    property NotificationController notificationController: null
    
    property GuideController guideController: null

    /* Object Properties
     * ****************************************************************************************/

    title: "Export / Import Project"
    icon: Style.icons.arowLeftRight


    content: ColumnLayout {

        GuideHoverTrigger {
            guideController: root.guideController
            guideId: "import_export_tutorial"
            guideName: "Export / Import Project"
            guideIcon: Style.icons.arowLeftRight
            guidePage: "utilities"
            stepsFactory: function() {
                return [
                    {
                        targetProvider: function() { return viewControl },
                        icon: Style.icons.arowLeftRight,
                        title: "Export / Import",
                        description: "Export packs the current branch history into a single .bundle file — a portable snapshot you can share or move without a remote server. Import loads commits from a bundle someone sent you back into this repository."
                    }
                ]
            }
        }

        ButtonGroup {
            id: headerButtonGroup
            exclusive: true
        }

        // View Control
        Rectangle {
            id: viewControl
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            radius: 10
            color: Style.colors.cardBackground

            RowLayout {
                anchors.fill: parent
                spacing: 4
                anchors.margins: 5

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

                    contentItem: Item {
                        anchors.fill: parent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: Style.icons.download
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: Style.appFont.mediumPt
                                color: Style.colors.foreground
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: "Export"
                                font.pixelSize: Style.appFont.h3Pt
                                color: Style.colors.foreground
                                Layout.alignment: Qt.AlignVCenter
                            }
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

                    contentItem: Item {
                        anchors.fill: parent

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                text: Style.icons.upload
                                font.family: Style.fontTypes.font6Pro
                                font.pixelSize: Style.appFont.mediumPt
                                color: Style.colors.foreground
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: "Import"
                                font.pixelSize: Style.appFont.h3Pt
                                color: Style.colors.foreground
                                Layout.alignment: Qt.AlignVCenter
                            }
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
                Layout.fillWidth: true
                Layout.fillHeight: true
                branchController: root.branchController
                bundleController: root.bundleController
                notificationController: root.notificationController
            }

            ImportView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                branchController: root.branchController
                bundleController: root.bundleController
                notificationController: root.notificationController
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
}
