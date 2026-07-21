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
    property BundleController   bundleController:     null
    property string             selectedFolder:       ""
    property NotificationController notificationController: null

    /* Object Properties (sized by parent layout when used in StackLayout)
     * ****************************************************************************************/
    implicitHeight: mainLayout.implicitHeight

    /* Children
     * ****************************************************************************************/
    FolderDialog {
        id: folderDialog
        title: "Select Directory"
        onAccepted: root.selectedFolder = folderDialog.selectedFolder.toString().replace(new RegExp("^file://+"), "")
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        spacing: 0

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Target Branch"
                font.pixelSize: Style.appFont.captionPt
                color: Style.colors.mutedText
            }

            ComboBox {
                id: branchesCombo
                Layout.fillWidth: true
                minHeight: Style.dp(25)
                focusBorderWidth: Style.dp(1)
                font.family: Style.fontTypes.inter
                font.weight: 400
                font.pixelSize: Style.appFont.smallPt
                textRole: "name"

                placeholderText: "Select branch"

                Material.background: Style.colors.primaryBackground
                Material.foreground: Style.colors.secondaryText

                background: Rectangle {
                    radius: Style.dp(5)
                    color: branchesCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }

                onCurrentIndexChanged: {
                    if (branchesCombo.currentIndex < 0)
                        return;
                    let targetBranch = branchesCombo.model[branchesCombo.currentIndex].name
                    console.log("Select Branch : ", targetBranch)
                    let res = branchController.getBranchLineage(targetBranch)
                    if (res.success)
                        baseBranchCombo.model = res.data
                    else
                        baseBranchCombo.model = []

                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Base Branch"
                font.pixelSize: Style.appFont.captionPt
                color: Style.colors.mutedText
            }

            ComboBox {
                id: baseBranchCombo
                Layout.fillWidth: true
                minHeight: Style.dp(25)
                focusBorderWidth: Style.dp(1)
                font.family: Style.fontTypes.inter
                font.weight: 400
                font.pixelSize: Style.appFont.smallPt

                placeholderText: "Select Base"

                Material.background: Style.colors.primaryBackground
                Material.foreground: Style.colors.secondaryText

                background: Rectangle {
                    radius: Style.dp(5)
                    color: baseBranchCombo.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                text: "Output Directory"
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
                        font.pixelSize: Style.appFont.smallPt
                        color: root.selectedFolder === "" ? Style.colors.placeholderText : Style.colors.secondaryText
                        text: root.selectedFolder !== "" ? root.selectedFolder : "Select Directory..."
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
                    tooltip: "Select Directory"

                    background: Rectangle {
                        radius: 6
                        color: fileButton.hovered ? Style.colors.accentHover : "transparent"
                        border.width: 1
                        border.color: Style.colors.primaryBorder
                    }

                    onClicked: folderDialog.open()
                }
            }
        }

        IconButton {
            id: exportButton
            Layout.fillWidth: true
            Layout.topMargin: Style.dp(5)
            implicitHeight: Style.dp(25)
            enabled: root.selectedFolder !== "" && branchesCombo.currentIndex !== -1 && baseBranchCombo.currentIndex !== -1

            display: IconButton.TextBesideIcon
            icon.name: Style.icons.download
            icon.width: Style.appFont.smallPt
            icon.height: Style.appFont.smallPt
            icon.color: Style.colors.secondaryForeground
            text: "Export"
            font.pixelSize: Style.appFont.mediumPt

            background: Rectangle {
                radius: Style.dp(4)
                color: exportButton.enabled ? Style.colors.accent : Style.colors.disabledButton
            }

            onClicked: {
                let base   = baseBranchCombo.model[baseBranchCombo.currentIndex]
                let target = branchesCombo.model[branchesCombo.currentIndex].name
                let refName = branchController.formatRefName(target)

                let bundleName = buildBundleName(base, target)
                let path = `${root.selectedFolder}/${bundleName}`

                let res = root.bundleController.buildDiffBundle(base, target, refName, path)

                if (res.success && root.notificationController) {
                    root.notificationController.success("Project exported successfully", "Export", 3000)
                } else if (!res.success && root.notificationController) {
                    root.notificationController.error(res.errorMessage || "Failed to export project", "Export Error", 5000)
                }
            }
        }
    }

    Connections {
        target: root.branchController

        function onCurrentRepoChanged() {
            updateBranches()
        }
    }

    onBranchControllerChanged: {
        updateBranches()
    }

    /* Functions
     * ****************************************************************************************/

    function updateBranches() {
        if(!branchController)
            return

        let branchNames = branchController.getBranches()

        branchesCombo.model = branchNames
    }

    /* Functions
     * ****************************************************************************************/

    function sanitizeBranchName(name) {
        return name
            .toLowerCase()
            .replace(/^refs\/heads\//, "")
            .replace(/[^a-z0-9._-]/g, "-")
            .replace(/-+/g, "-")
            .replace(/^-|-$/g, "");
    }

    function formatTimestamp() {
        let d = new Date();
        let pad = n => n.toString().padStart(2, "0");

        return d.getFullYear().toString() +
               pad(d.getMonth() + 1) +
               pad(d.getDate()) + "-" +
               pad(d.getHours()) +
               pad(d.getMinutes()) +
               pad(d.getSeconds());
    }

    function buildBundleName(base, target) {
        let baseSafe   = sanitizeBranchName(base);
        let targetSafe = sanitizeBranchName(target);
        let ts         = formatTimestamp();

        return `${baseSafe}__to__${targetSafe}__${ts}`;
    }
}
