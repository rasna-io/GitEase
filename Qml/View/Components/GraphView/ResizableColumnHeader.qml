import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GitEase_Style

/*! ***********************************************************************************************
 * ResizableColumnHeader – a column header with a draggable right divider.
 * signal resized(delta, startWidth) is emitted when the divider is dragged.
 * ************************************************************************************************/
Rectangle {
    id: root

    property string label: ""

    // width at the moment the drag began (captured in onPressed)
    property real dragStartWidth: 0

    signal resized(real delta, real startWidth)
    signal resizeStarted()
    signal resizeFinished()

    Layout.fillHeight: true
    color: headerMouse.containsMouse ? Style.colors.hoverTitle : "transparent"

    Label {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: 5
        text: root.label
        color: Style.colors.foreground
        font.pixelSize: Style.appFont.defaultPt
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

            // Global coordinate tracking to avoid feedback loop
            property real startGlobalX: 0

            onPressed: (mouse) => {
                startGlobalX = dividerMouse.mapToItem(null, mouse.x, mouse.y).x
                root.dragStartWidth = parent.parent.Layout.preferredWidth
                root.resizeStarted()
            }

            onPositionChanged: (mouse) => {
                if (!pressed) return
                var currentGlobalX = dividerMouse.mapToItem(null, mouse.x, mouse.y).x
                var delta = currentGlobalX - startGlobalX
                root.resized(delta, root.dragStartWidth)
            }

            onReleased: {
                root.resizeFinished()
            }
        }
    }
}
