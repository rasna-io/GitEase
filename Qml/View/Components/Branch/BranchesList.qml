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
    spacing: 0
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

        readonly property var  branch:     modelData
        readonly property bool isSelected: branchDelegate.branch.name === root.currentBranch

        width: root.width
        height: Style.dp(28)
        radius: 4

        color: branchDelegate.isSelected ? Style.colors.utilitiesRowSelectedBackground
                                         : (hoverHandler.hovered ? Style.colors.utilitiesRowHoverBackground
                                                                 : "transparent")

        border.width: 0

        HoverHandler {
            id: hoverHandler
        }

        //! Selected-row indicator
        Rectangle {
            id: selectedIndicator
            visible: branchDelegate.isSelected
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Style.dp(3)
            radius: Style.dp(1.5)
            color: Style.colors.utilitiesRowSelectedIndicator
        }

        //! Every branch action lives in the context menu
        MouseArea {
            id: rightClickArea
            anchors.fill: parent
            acceptedButtons: Qt.RightButton
            onClicked: (mouse) => {
                if(!root.isLocal)
                    return

                var pos = mapToItem(Overlay.overlay, mouse.x, mouse.y)
                itemContextMenu.menuModel = root.buildBranchMenu(branchDelegate.branch)
                itemContextMenu.x = pos.x
                itemContextMenu.y = pos.y
                itemContextMenu.open()
            }
        }

        RowLayout {
            anchors.fill: parent
            //! Constant inset so rows stay aligned whether or not the indicator is shown
            anchors.leftMargin: Style.dp(8)
            anchors.rightMargin: Style.dp(8)
            spacing: Style.dp(6)

            Text {
                text: root.isLocal ? Style.icons.branch : Style.icons.globe
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: Style.appFont.smallPt
                color: branchDelegate.isSelected ? Style.colors.utilitiesRowSelectedText
                                                 : Style.colors.utilitiesRowIcon
                Layout.alignment: Qt.AlignVCenter
            }

            ScrollingText {
                text: branchDelegate.branch.name
                Layout.fillWidth: true
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.smallPt
                font.bold: branchDelegate.isSelected
                color: branchDelegate.isSelected ? Style.colors.utilitiesRowSelectedText
                                                 : Style.colors.utilitiesRowText
            }

            Text {
                text: "HEAD"
                visible: branchDelegate.isSelected
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.microPt
                font.bold: true
                font.letterSpacing: Style.dp(0.5)
                color: Style.colors.utilitiesRowSelectedText
                Layout.alignment: Qt.AlignVCenter
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

    function copyBranchHash(branch) {
        clipboardHelper.text = branch.targetHash
        clipboardHelper.selectAll()
        clipboardHelper.copy()
        if (root.notificationController)
            root.notificationController.success("Commit SHA copied to clipboard", "Branch", 2000)
    }

    function buildBranchMenu(branch) {

        var menu = []

        if (root.isLocal){

            if (branch.name !== root.currentBranch) {
                menu.push({
                    text: "Checkout",
                    icon: Style.icons.branchPlus,
                    action: function() { root.doCheckout(branch) }
                })

                menu.push({ separator: true })
            }

            // Rename
            menu.push({
                text: "Rename...",
                icon: Style.icons.edit,
                action: function() {
                    // TODO
                }
            })

            // Delete
            if (branch.name !== root.currentBranch) {
                menu.push({
                    text: "Delete",
                    icon: Style.icons.trash,
                    color: Style.colors.contextMenuDanger,
                    action: function() { root.doDeleteBranch(branch) }
                })
            }

            menu.push({ separator: true })

            // Merge
            menu.push({
                text: "Merge into current",
                icon: Style.icons.arowLeftRight,
                action: function() {
                    // TODO
                }
            })

            // Rebase
            menu.push({
                text: "Rebase onto current",
                icon: Style.icons.clockRotateLeft,
                action: function() {
                    // TODO
                }
            })

            // Cherry-pick
            menu.push({
                text: "Cherry-pick range...",
                icon: Style.icons.copy,
                action: function() {
                    // TODO
                }
            })

            menu.push({ separator: true })

            // Reset
            menu.push({
                text: "Reset current to here...",
                icon: Style.icons.reset,
                action: function() {
                    // TODO
                }
            })

            menu.push({ separator: true })

            menu.push({
                text: "Copy Branch Name",
                icon: Style.icons.copy,
                action: function() { root.copyBranchName(branch) }
                })

            menu.push({
                text: "Copy Full SHA",
                icon: Style.icons.copy,
                action: function() { root.copyBranchHash(branch) }
                })
        } else {

            menu.push({
                text: "Fetch",
                icon: Style.icons.download,
                action: function() {
                    // TODO
                }
            })

            menu.push({
                text: "Pull",
                icon: Style.icons.arrowDown,
                action: function() {
                    // TODO
                }
            })

            menu.push({
                text: "Push",
                icon: Style.icons.arrowUp,
                action: function() {
                    // TODO
                }
            })

            menu.push({ separator: true })

            menu.push({
                text: "Edit Remote...",
                icon: Style.icons.edit,
                action: function() {
                    // TODO
                }
            })

            menu.push({
                text: "Delete Remote",
                icon: Style.icons.trash,
                color: Style.colors.contextMenuDanger,
                action: function() {
                    // TODO
                }
            })

            menu.push({ separator: true })

            menu.push({
                text: "Copy URL",
                icon: Style.icons.copy,
                action: function() {
                    // TODO
                }
            })
        }

        return menu
    }
}
