import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * BranchesList
 * Displays the local/remote branches based on the given model
 * ************************************************************************************************/

ListView {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool isLocal: false
    property string currentBranch: ""
    property var branchController: null
    property var notificationController: null
    property int maxHeight: 220

    /* Signals
     * ****************************************************************************************/
    signal updateRequested()

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    Layout.preferredHeight: Math.min(contentHeight, maxHeight)
    spacing: 4
    clip: true

    ScrollBar.vertical: ScrollBar {
        policy: ScrollBar.AsNeeded
    }

    ContextMenu {
        id: itemContextMenu
        parent: Overlay.overlay
        width: 200
    }

    TextEdit {
        id: clipboardHelper
        visible: false
    }

    delegate: Rectangle {
        id: branchDelegate
        property var branch: modelData
        property bool hovered: false

        width: root.width
        height: 32
        radius: 4
        color: branch.name === root.currentBranch ? Style.colors.accent
             : hoverHandler.hovered ? Style.colors.surfaceLight
             : Style.colors.secondaryBackground

        HoverHandler {
            id: hoverHandler
        }

        MouseArea {
            id: rightClickArea
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: (mouse) => {
                var pos = mapToItem(Overlay.overlay, mouse.x, mouse.y)
                itemContextMenu.menuModel = root.buildBranchMenu(branch)
                itemContextMenu.x = pos.x
                itemContextMenu.y = pos.y
                itemContextMenu.open()
            }
        }

        RowLayout {
            anchors.fill: parent
            anchors.margins: 6
            spacing: 6

            ScrollingText {
                text: branch.name
                Layout.fillWidth: true
                font.family: Style.fontTypes.roboto
                font.pixelSize: Style.appFont.smallPt
                font.bold: branch.name === root.currentBranch
                color: Style.colors.foreground
            }

            RowLayout {
                spacing: 4
                Layout.alignment: Qt.AlignVCenter

                RowLayout {
                    spacing: 3
                    visible: branch.name !== root.currentBranch

                    MouseArea {
                        id: checkoutArea
                        Layout.preferredWidth: checkoutRow.implicitWidth
                        Layout.preferredHeight: checkoutRow.implicitHeight
                        cursorShape: Qt.PointingHandCursor

                        onClicked: root.doCheckout(branch)

                        RowLayout {
                            id: checkoutRow
                            anchors.fill: parent
                            spacing: 4

                            Text {
                                text: Style.icons.check
                                font.family: Style.fontTypes.font6Pro
                                color: !hoverHandler.hovered ? Style.colors.accent : Qt.darker(Style.colors.accent, 1.5)
                                font.pixelSize: Style.appFont.smallPt
                                font.bold: true
                                Layout.alignment: Qt.AlignVCenter
                            }

                            Text {
                                text: "Checkout"
                                font.family: Style.fontTypes.roboto
                                color: !hoverHandler.hovered ? Style.colors.accent : Qt.darker(Style.colors.accent, 1.5)
                                font.pixelSize: Style.appFont.smallPt
                                font.bold: true
                                Layout.alignment: Qt.AlignVCenter
                            }
                        }
                    }
                }

                // Delete Button
                ActionIconButton {
                    iconText: Style.icons.trash
                    textColor: Style.colors.deletededFile
                    tooltip: "Delete Branch"
                    visible: branch.name !== root.currentBranch && root.isLocal
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: root.doDeleteBranch(branch)
                }
            }
        }
    }

    /* Functions
     * ****************************************************************************************/
    function doCheckout(branch) {
        if (branch.name.startsWith("origin/")) {
            // Extract the local name (everything after 'origin/')
            let localName = branch.name.split('/').slice(1).join('/');

            // Create a local branch pointing to the remote's SHA
            let res = root.branchController.createBranch(branch.targetHash, localName);

            if (res.success) {
                // Checkout the newly created local branch
                let checkoutRes = root.branchController.checkoutBranch(localName);
                if (checkoutRes.success && root.notificationController) {
                    root.notificationController.success("Checked out branch '" + localName + "'", "Checkout", 3000)
                } else if (!checkoutRes.success && root.notificationController) {
                    root.notificationController.error(checkoutRes.errorMessage || "Failed to checkout branch", "Checkout Error", 5000)
                }
            } else {
                if (root.notificationController) {
                    root.notificationController.error(res.errorMessage || "Failed to track remote branch", "Branch Error", 5000)
                }
            }
        } else {
            // Normal local checkout
            let res = root.branchController.checkoutBranch(branch.name);
            if (res.success && root.notificationController) {
                root.notificationController.success("Checked out branch '" + branch.name + "'", "Checkout", 3000)
            } else if (!res.success && root.notificationController) {
                root.notificationController.error(res.errorMessage || "Failed to checkout branch", "Checkout Error", 5000)
            }
        }

        root.updateRequested()
    }

    function doDeleteBranch(branch) {
        let res = root.branchController.deleteBranch(branch.name)

        if (res.success) {
            if (root.notificationController) {
                root.notificationController.success("Branch '" + branch.name + "' deleted successfully", "Branch", 3000)
            }
            root.updateRequested()
        } else {
            if (root.notificationController) {
                root.notificationController.error(res.errorMessage || "Failed to delete branch", "Branch Error", 5000)
            }
        }
    }

    function copyBranchName(branch) {
        clipboardHelper.text = branch.name
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        if (root.notificationController)
            root.notificationController.success("Branch name copied to clipboard", "Branch", 2000)
    }

    function buildBranchMenu(branch) {
        var items = [{
            text: "Copy Branch Name",
            icon: Style.icons.copy,
            action: function() { root.copyBranchName(branch) }
        }]

        var actions = []

        if (branch.name !== root.currentBranch) {
            actions.push({
                text: "Checkout",
                icon: Style.icons.check,
                action: function() { root.doCheckout(branch) }
            })
        }

        if (branch.name !== root.currentBranch && root.isLocal) {
            actions.push({
                text: "Delete Branch",
                icon: Style.icons.trash,
                action: function() { root.doDeleteBranch(branch) }
            })
        }

        if (actions.length > 0) {
            items.push({ separator: true })
            items = items.concat(actions)
        }

        return items
    }
}
