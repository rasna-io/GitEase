import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GitEase_Style

/*! ***********************************************************************************************
 * ResizableColumnHeader – a column header with a draggable right divider.
 * Emits resized(delta, startWidth) from the drag origin so callers can size
 * against a stable baseline (avoids feedback loops with live layout widths).
 * ************************************************************************************************/
Item {
    id: root

    property string label: ""
    property bool   resizable: true
    property bool   fillWidth: false
    property real   contentPadding: 8

    // width at the moment the drag began (captured in onPressed)
    property real dragStartWidth: 0

    signal resized(real delta, real startWidth)
    signal resizeStarted()
    signal resizeFinished()

    Layout.fillHeight: true
    Layout.fillWidth: root.fillWidth
    // Fixed columns lock their width so header cells stay pixel-aligned with row cells.
    // The flex (Message) column leaves min/max unset and fills remaining space.
    Layout.minimumWidth: root.fillWidth ? 0 : Layout.preferredWidth
    Layout.maximumWidth: root.fillWidth ? 100000 : Layout.preferredWidth
    clip: true

    Rectangle {
        anchors.fill: parent
        color: headerMouse.containsMouse || dividerMouse.pressed
               ? Style.colors.hoverTitle
               : "transparent"
    }

    Label {
        anchors.left: parent.left
        anchors.right: divider.visible ? divider.left : parent.right
        anchors.verticalCenter: parent.verticalCenter
        leftPadding: root.contentPadding
        rightPadding: 4
        text: root.label
        color: Style.colors.foreground
        font.pixelSize: Style.appFont.defaultPt
        font.bold: true
        elide: Text.ElideRight
    }

    MouseArea {
        id: headerMouse
        anchors.fill: parent
        anchors.rightMargin: root.resizable ? 6 : 0
        hoverEnabled: true
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
        onReleased: (mouse) => mouse.accepted = false
    }

    // Right edge divider + drag area
    Rectangle {
        id: divider
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        visible: root.resizable
        color: dividerMouse.pressed || dividerMouse.containsMouse
               ? Style.colors.resizeHandlePressed
               : Style.colors.resizeHandle

        MouseArea {
            id: dividerMouse
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: 12
            anchors.rightMargin: -6
            hoverEnabled: true
            cursorShape: Qt.SizeHorCursor
            enabled: root.resizable
            preventStealing: true

            // Global coordinate tracking to avoid feedback loop
            property real startGlobalX: 0

            onPressed: (mouse) => {
                startGlobalX = dividerMouse.mapToItem(null, mouse.x, mouse.y).x
                root.dragStartWidth = root.width
                root.resizeStarted()
                mouse.accepted = true
            }

            onPositionChanged: (mouse) => {
                if (!pressed)
                    return
                var currentGlobalX = dividerMouse.mapToItem(null, mouse.x, mouse.y).x
                root.resized(currentGlobalX - startGlobalX, root.dragStartWidth)
            }

            onReleased: {
                root.resizeFinished()
            }
        }
    }
}
