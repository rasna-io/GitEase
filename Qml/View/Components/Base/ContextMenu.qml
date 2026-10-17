import QtQuick
import QtQuick.Window

/*! ***********************************************************************************************
 * ContextMenu
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    //! Format: [{ text: "Checkout", icon: "\uf00c", action: function(){}, enabled: true,
    //!            color: "#DC3545",      // optional: tints both label and icon
    //!            iconColor: "#DC3545" }] // optional: tints the icon only
    property var menuModel: []

    readonly property bool opened: mainWindow.visible

    /* Signals
     * ****************************************************************************************/
    signal closed()

    /* Functions
     * ****************************************************************************************/
    function open() {
        const origin = root.parent ? root.parent.mapToGlobal(root.x, root.y) : Qt.point(root.x, root.y)

        mainWindow.menuWidth = root.width
        mainWindow.menuModel = root.menuModel
        subWindow.hideNow()

        const screens = Qt.application.screens
        let left = 0
        let top = 0
        let right = 0
        let bottom = 0
        for(let i = 0; i < screens.length; ++i) {
            const s = screens[i]
            left = Math.min(left, s.virtualX)
            top = Math.min(top, s.virtualY)
            right = Math.max(right, s.virtualX + s.width)
            bottom = Math.max(bottom, s.virtualY + s.height)
        }
        catcher.x = left
        catcher.y = top
        catcher.width = right - left
        catcher.height = bottom - top
        catcher.visible = true

        mainWindow.openAt(Qt.rect(origin.x, origin.y, 0, 0))
    }

    function close() {
        //! Clicks pass through again while the close animation plays
        catcher.visible = false
        subWindow.hideAnimated()
        mainWindow.hideAnimated()
    }

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 200

    Component.onDestruction: {
        catcher.visible = false
        subWindow.hideNow()
        mainWindow.hideNow()
    }

    /* Children
     * ****************************************************************************************/
    Window {
        id: catcher

        flags: Qt.Tool | Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.WindowDoesNotAcceptFocus
        color: Qt.rgba(0, 0, 0, 0.01)
        visible: false

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.AllButtons
            onPressed: {
                root.close()
            }
        }
    }

    ContextMenuWindow {
        id: mainWindow

        //! Owned windows stay above their owner, which keeps the menu above the catcher
        transientParent: catcher

        placement: "cursor"

        //! Windows closes a menu as soon as something else takes the focus
        property bool wasActive: false

        onActiveChanged: {
            if(active) {
                wasActive = true
            } else if(wasActive && visible) {
                root.close()
            }
        }

        onVisibleChanged: {
            wasActive = false
        }

        onItemHovered: (item, itemRect) => {
            if(item.subItems && item.subItems.length > 0) {
                subWindow.hideNow()
                subWindow.menuModel = item.subItems
                subWindow.openAt(itemRect)
            } else {
                subWindow.hideAnimated()
            }
        }

        onItemTriggered: (item, checked) => {
            item.action(checked)
            root.close()
        }

        onDismissRequested: {
            root.close()
        }

        onHidden: {
            subWindow.hideNow()
            root.closed()
        }
    }

    ContextMenuWindow {
        id: subWindow

        placement: "side"
        menuWidth: 240
        transientParent: mainWindow
        acceptsFocus: false
        preferLeft: mainWindow.flippedX

        onItemTriggered: (item, checked) => {
            item.action(checked)
            root.close()
        }
    }
}
