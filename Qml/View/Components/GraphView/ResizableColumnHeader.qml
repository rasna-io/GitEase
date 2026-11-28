import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ResizableColumnHeader – a column header with a draggable right divider.
 * Emits resized(delta, startWidth) from the drag origin so callers can size
 * against a stable baseline (avoids feedback loops with live layout widths).
 * Double-click the divider to auto-fit the column to its content (Excel-style).
 * ************************************************************************************************/
Item {
    id: root

    property string label: ""
    property bool   resizable: true
    property bool   fillWidth: false
    property bool   autoFitEnabled: true
    property real   contentPadding: 8

    // width at the moment the drag began (captured in onPressed)
    property real dragStartWidth: 0
    readonly property bool resizing: dividerMouse.pressed
    readonly property bool handleHot: dividerMouse.containsMouse || dividerMouse.pressed

    signal resized(real delta, real startWidth)
    signal resizeStarted()
    signal resizeFinished()
    signal autoFitRequested()

    Layout.fillHeight: true
    Layout.fillWidth: root.fillWidth
    // Fixed columns lock their width so header cells stay pixel-aligned with row cells.
    // The flex (Message) column leaves min/max unset and fills remaining space.
    Layout.minimumWidth: root.fillWidth ? 0 : Layout.preferredWidth
    Layout.maximumWidth: root.fillWidth ? 100000 : Layout.preferredWidth
    clip: true

    Rectangle {
        anchors.fill: parent
        color: (headerMouse.containsMouse && !root.handleHot) || root.resizing
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
        anchors.rightMargin: root.resizable ? 8 : 0
        hoverEnabled: true
        propagateComposedEvents: true
        onPressed: (mouse) => mouse.accepted = false
        onReleased: (mouse) => mouse.accepted = false
    }

    // Right edge divider + drag area (thickens on hover like SplitViewHandle)
    Item {
        id: divider
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: 1
        visible: root.resizable
        z: 2

        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: root.handleHot ? 3 : 1
            radius: width / 2
            color: dividerMouse.pressed ? Style.colors.accent
                 : dividerMouse.containsMouse ? Style.colors.resizeHandlePressed
                 : Style.colors.resizeHandle

            Behavior on width {
                NumberAnimation {
                    duration: Style.reducedMotion ? 0 : 120
                    easing.type: Easing.OutCubic
                }
            }
        }

        MouseArea {
            id: dividerMouse
            anchors.centerIn: parent
            width: 14
            height: parent.height
            hoverEnabled: true
            // SplitHCursor is the Excel-style column resize cursor (bar + arrows)
            cursorShape: Qt.SplitHCursor
            enabled: root.resizable
            preventStealing: true

            property real startGlobalX: 0
            property bool moved: false

            AppToolTip {
                visible: dividerMouse.containsMouse && !dividerMouse.pressed
                delay: 600
                text: root.autoFitEnabled
                      ? qsTr("Drag to resize · double-click to auto-fit")
                      : qsTr("Drag to resize")
            }

            onPressed: (mouse) => {
                startGlobalX = dividerMouse.mapToItem(null, mouse.x, mouse.y).x
                moved = false
                root.dragStartWidth = root.width
                root.resizeStarted()
                mouse.accepted = true
            }

            onPositionChanged: (mouse) => {
                if (!pressed)
                    return
                var currentGlobalX = dividerMouse.mapToItem(null, mouse.x, mouse.y).x
                var delta = currentGlobalX - startGlobalX
                if (Math.abs(delta) >= 2)
                    moved = true
                // Ignore tiny motion so a double-click does not nudge the column first
                if (!moved)
                    return
                root.resized(delta, root.dragStartWidth)
            }

            onReleased: {
                root.resizeFinished()
            }

            onDoubleClicked: {
                if (!root.autoFitEnabled)
                    return
                root.resizeFinished()
                root.autoFitRequested()
            }
        }
    }
}
