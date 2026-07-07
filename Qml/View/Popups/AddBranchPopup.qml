import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * AddBranchPopup
 * ************************************************************************************************/
IPopup {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property BranchController       branchController
    property NotificationController notificationController: null

    property string targetHash: ""

    readonly property bool    isNameValid: nameInput.text.trim().length > 0

    readonly property bool    canAccept:   isNameValid

    /* Signals
     * ****************************************************************************************/
    signal branchCreatedSuccessfully()

    /* Object Properties
     * ****************************************************************************************/

    width: 360
    height: 220
    padding: 20

    contentItem: Rectangle {
        color: Style.colors.primaryBackground
        radius: 16
        clip: true
        border.color: Style.colors.accent
        border.width: 1

        ColumnLayout {
            spacing: 20
            anchors.fill: parent
            anchors.margins: 20

            Text {
                text: "Create Branch"
                color: Style.colors.foreground
                font.family: Style.fontTypes.roboto
                font.bold: true
                font.pixelSize: Style.appFont.h2Pt
                Layout.alignment: Qt.AlignHCenter
            }

            ColumnLayout {
                spacing: 12
                Layout.fillWidth: true

                // Name Input
                TextField {
                    id: nameInput
                    placeholderText: "Branch Name "
                    Layout.fillWidth: true
                    selectByMouse: true

                    background: Rectangle {
                        implicitHeight: 40
                        color: Style.colors.secondaryBackground
                        radius: 5
                        border.color: nameInput.activeFocus ? Style.colors.accent : "transparent"
                    }
                }
            }

            RowLayout {
                spacing: 8
                Layout.fillWidth: true

                Button {
                    text: "Cancel"
                    Layout.preferredWidth: 120
                    onClicked: root.close()
                    Material.foreground: Style.colors.foreground

                    background: Rectangle {
                        implicitHeight: 35
                        color: parent.hovered ? "#33ffffff" : "transparent"
                        border.color: Style.colors.accent
                        radius: 5
                    }
                }

                Button {
                    id: actionBtn
                    text: "Create"
                    Layout.fillWidth: true
                    enabled: root.canAccept
                    Material.foreground: Style.colors.textButton

                    opacity: enabled ? 1.0 : 0.5

                    background: Rectangle {
                        implicitHeight: 35
                        color: actionBtn.enabled ? (actionBtn.hovered) ? Style.colors.accentHover : Style.colors.accent
                                                    : (Style.colors.disabledButton)
                        border.color: Style.colors.accent
                        radius: 5
                    }

                    onClicked: {
                        let res;

                        if (root.targetHash === "") {
                            res = root.branchController.createBranch(nameInput.text);
                        } else {
                            res = root.branchController.createBranch(root.targetHash, nameInput.text);
                            root.branchController.checkoutBranch(nameInput.text);
                        }

                        if (res && res.success) {
                            root.branchCreatedSuccessfully()
                            notificationController.success("Branch '" + nameInput.text + "' created successfully", "Branch", 3000)
                            root.close();
                        } else {
                            console.error("Error creating branch:", res.message);
                            notificationController.error(res.errorMessage || "Failed to create branch", "Branch Error", 5000)
                        }
                    }
                }
            }
        }
    }

    onAboutToHide: {
        nameInput.text = "";
        targetHash = "";
    }
}
