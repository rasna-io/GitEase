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
        anchors.fill: parent
        anchors.leftMargin: Style.dp(10)
        anchors.rightMargin: Style.dp(10)

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
            Layout.preferredHeight: Style.dp(27)
            radius: Style.dp(5)
            color: Style.colors.utilitiesSegmentTrackBackground

            border {
                width: Style.dp(1)
                color: Style.colors.utilitiesSegmentTrackBorder
            }

            RowLayout {
                anchors.fill: parent
                spacing: 4
                anchors.margins: 3

                IconButton {
                    id: exportBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    topInset: 0
                    bottomInset: 0
                    verticalPadding: 6

                    checkable: true
                    checked: root.currentIndex === 0
                    ButtonGroup.group: headerButtonGroup

                    display: IconButton.TextBesideIcon
                    icon.name: Style.icons.download
                    icon.width: Style.appFont.mediumPt
                    icon.height: Style.appFont.mediumPt
                    icon.color: exportBtn.checked ? Style.colors.utilitiesSegmentSelectedText
                                                  : Style.colors.utilitiesSegmentText
                    text: "Export"
                    font.pixelSize: Style.appFont.mediumPt

                    background: Rectangle {
                        radius: viewControl.radius
                        color: exportBtn.checked ? Style.colors.utilitiesSegmentSelectedBackground
                               : (exportBtn.hovered ? Style.colors.utilitiesSegmentHoverBackground
                                                    : "transparent")
                    }

                    onClicked: root.currentIndex = 0
                }

                IconButton {
                    id: importBtn
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    topInset: 0
                    bottomInset: 0
                    verticalPadding: 6

                    checkable: true
                    checked: root.currentIndex === 1
                    ButtonGroup.group: headerButtonGroup

                    display: IconButton.TextBesideIcon
                    icon.name: Style.icons.upload
                    icon.width: Style.appFont.mediumPt
                    icon.height: Style.appFont.mediumPt
                    icon.color: importBtn.checked ? Style.colors.utilitiesSegmentSelectedText
                                                  : Style.colors.utilitiesSegmentText
                    text: "Import"
                    font.pixelSize: Style.appFont.mediumPt

                    background: Rectangle {
                        radius: viewControl.radius
                        color: importBtn.checked ? Style.colors.utilitiesSegmentSelectedBackground
                               : (importBtn.hovered ? Style.colors.utilitiesSegmentHoverBackground
                                                    : "transparent")
                    }

                    onClicked: root.currentIndex = 1
                }
            }
        }

        // Content Area
        StackLayout {
            Layout.fillWidth: true
            currentIndex: root.currentIndex

            ExportView {
                Layout.fillWidth: true
                branchController: root.branchController
                bundleController: root.bundleController
                notificationController: root.notificationController
            }

            ImportView {
                Layout.fillWidth: true
                branchController: root.branchController
                bundleController: root.bundleController
                notificationController: root.notificationController
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
}
