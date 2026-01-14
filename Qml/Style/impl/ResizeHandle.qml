import QtQuick

Item {
    id: root

    enum Handle {
        Left,
        Right,
        Top,
        Bottom,
        TopLeft,
        TopRight,
        BottomLeft,
        BottomRight
    }

    property Item target: parent
    property int handle: ResizeHandle.Right
    property real thickness: 8

    // Minimum/maximum constraints (applied when resizing width/height)
    property real minWidth: 0
    property real minHeight: 0
    property real maxWidth: Infinity
    property real maxHeight: Infinity

    // Visuals
    property color handleColor: "transparent"
    property real idleOpacity: 0.0
    property real hoverOpacity: 0.35
    property real pressedOpacity: 0.55

    readonly property bool isCornerHandle: root.handle === ResizeHandle.TopLeft
                                          || root.handle === ResizeHandle.TopRight
                                          || root.handle === ResizeHandle.BottomLeft
                                          || root.handle === ResizeHandle.BottomRight
    readonly property bool isVerticalHandle: root.handle === ResizeHandle.Left
                                            || root.handle === ResizeHandle.Right
    readonly property bool isHorizontalHandle: root.handle === ResizeHandle.Top
                                              || root.handle === ResizeHandle.Bottom

    implicitWidth: (isVerticalHandle || isCornerHandle) ?
                       mouseArea.containsMouse ? thickness : thickness * 0.5 : 0
    implicitHeight: (isHorizontalHandle || isCornerHandle) ?
                        mouseArea.containsMouse ? thickness : thickness * 0.5 : 0

    readonly property int cursorShape: {
        switch (root.handle) {
            case ResizeHandle.Left:
            case ResizeHandle.Right:
                return Qt.SizeHorCursor
            case ResizeHandle.Top:
            case ResizeHandle.Bottom:
                return Qt.SizeVerCursor
            case ResizeHandle.TopLeft:
            case ResizeHandle.BottomRight:
                return Qt.SizeFDiagCursor
            case ResizeHandle.TopRight:
            case ResizeHandle.BottomLeft:
                return Qt.SizeBDiagCursor
            default:
                return Qt.ArrowCursor
        }
    }

    Rectangle {
        anchors.fill: parent
        color: root.handleColor
        radius: 2
        opacity: mouseArea.pressed ? root.pressedOpacity :
                                     (mouseArea.containsMouse ? root.hoverOpacity : root.idleOpacity)
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 120
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.cursorShape

        property real startMouseX: 0
        property real startMouseY: 0

        property real startX: 0
        property real startY: 0
        property real startW: 0
        property real startH: 0

        onPressed: function(mouse) {
            if (!root.target)
                return

            startMouseX = mouse.x
            startMouseY = mouse.y

            startX = root.target.x
            startY = root.target.y
            startW = root.target.width
            startH = root.target.height
        }

        onPositionChanged: function(mouse) {
            if (!pressed)
                return

            if (!root.target)
                return

            const deltaX = mouse.x - startMouseX
            const deltaY = mouse.y - startMouseY

            // Width
            if (root.handle === ResizeHandle.Right
                    || root.handle === ResizeHandle.TopRight
                    || root.handle === ResizeHandle.BottomRight) {
                root.target.width = root.clamp(startW + deltaX, root.minWidth, root.maxWidth)
            }

            if (root.handle === ResizeHandle.Left
                    || root.handle === ResizeHandle.TopLeft
                    || root.handle === ResizeHandle.BottomLeft) {
                const newW = root.clamp(startW - deltaX, root.minWidth, root.maxWidth)
                root.target.x = startX + (startW - newW)
                root.target.width = newW
            }

            // Height
            if (root.handle === ResizeHandle.Bottom
                    || root.handle === ResizeHandle.BottomLeft
                    || root.handle === ResizeHandle.BottomRight) {
                root.target.height = root.clamp(startH + deltaY, root.minHeight, root.maxHeight)
            }

            if (root.handle === ResizeHandle.Top
                    || root.handle === ResizeHandle.TopLeft
                    || root.handle === ResizeHandle.TopRight) {
                const newH = root.clamp(startH - deltaY, root.minHeight, root.maxHeight)
                root.target.y = startY + (startH - newH)
                root.target.height = newH
            }
        }
    }

    function clamp(v, lo, hi) {
        return Math.max(lo, Math.min(hi, v))
    }
}
