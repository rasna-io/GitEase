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
        subWindow.hide()

        mainWindow.openAt(Qt.rect(origin.x, origin.y, 0, 0))
    }

    function close() {
        subWindow.hide()
        mainWindow.hide()
    }

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: 200

    Component.onDestruction: {
        subWindow.hide()
        mainWindow.hide()
    }

    /* Children
     * ****************************************************************************************/
    MouseArea {
        parent: root.Window.window ? root.Window.window.contentItem : null
        anchors.fill: parent
        z: 100000
        enabled: root.opened
        acceptedButtons: Qt.AllButtons
        onPressed: (mouse) => {
            mouse.accepted = false
            root.close()
        }
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.opened
        onActivated: {
            root.close()
        }
    }

    Connections {
        target: root.Window.window
        enabled: root.opened

        function onActiveChanged() {
            if(!root.Window.window.active) {
                root.close()
            }
        }
    }

    ContextMenuWindow {
        id: mainWindow

        transientParent: root.Window.window

        placement: ContextMenuWindow.Placement.Cursor

        onItemHovered: (item, itemRect) => {
            if(item.subItems && item.subItems.length > 0) {
                subWindow.hide()
                subWindow.menuModel = item.subItems
                subWindow.openAt(itemRect)
                subWindow.raise()
            } else {
                subWindow.hide()
            }
        }

        onItemTriggered: (item, checked) => {
            item.action(checked)
            root.close()
        }

        onHidden: {
            subWindow.hide()
            root.closed()
        }
    }

    ContextMenuWindow {
        id: subWindow

        placement: ContextMenuWindow.Placement.Side
        menuWidth: 240
        transientParent: mainWindow
        preferLeft: mainWindow.flippedX

        onItemTriggered: (item, checked) => {
            item.action(checked)
            root.close()
        }
    }
}
