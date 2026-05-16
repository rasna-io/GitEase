import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GitEase_Style

/*! ***********************************************************************************************
 * ResizableColumnHeader – a column header with a draggable right divider.
 * signal resized(delta) is emitted when the divider is dragged.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string label: ""

    /* Signals
     * ****************************************************************************************/
    signal resized(real delta)
    signal resizeStarted()
    signal resizeFinished()

    /* Object Properties
     * ****************************************************************************************/

    Layout.fillHeight: true
    color: headerMouse.containsMouse ? Style.colors.hoverTitle : "transparent"

    /* Children
     * ****************************************************************************************/
    Label {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: 5
        text: root.label
        color: Style.colors.foreground
        font.pixelSize: 11
        font.bold: true
        elide: Text.ElideRight
    }

    MouseArea {
        id: headerMouse
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
        onReleased: (mouse) => mouse.accepted = false
    }

    // Right edge divider + drag area
    Rectangle {
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        color: dividerMouse.pressed ? Style.colors.resizeHandlePressed : Style.colors.resizeHandle

        MouseArea {
            id: dividerMouse
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 10
            anchors.rightMargin: -5
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor

            property real startX: 0
            property real startWidth: parent.parent.Layout.preferredWidth

            onPressed: (mouse) => {
                startX = mouseX + mapToItem(parent.parent.parent, 0, 0).x
                startWidth = parent.parent.Layout.preferredWidth
                root.resizeStarted()
            }

            onPositionChanged: (mouse) => {
                if (!pressed) return
                var currentX = mouseX + mapToItem(parent.parent.parent, 0, 0).x
                var delta = currentX - startX
                root.resized(delta)
            }

            onReleased: {
                root.resizeFinished()
            }
        }
    }
}
