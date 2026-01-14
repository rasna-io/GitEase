import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase

/*! ***********************************************************************************************
 * TabGroupSide
 * Tab group for multiple docks in the same area
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var docks: []
    property int activeIndex: 0
    property int position: Enums.DockPosition.Left

    // Preferred thickness for this dock area.
    // - Left/Right: width
    // - Top/Bottom: height
    property real preferredSize: 300
    property real minPreferredSize: 160
    property real maxPreferredSize: 1000

    readonly property bool isVertical: position === Enums.DockPosition.Left || position === Enums.DockPosition.Right
    readonly property real handleSize: 4

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: isVertical ? preferredSize : 0
    implicitHeight: isVertical ? 0 : preferredSize

    /* Children
     * ****************************************************************************************/
    onDocksChanged: {
        if (root.docks.length && activeIndex >= root.docks.length) {
            activeIndex = Math.max(0, root.docks.length - 1)
        }
    }

    Rectangle {
        anchors.fill: parent
        border.color: "#c9c9c9"
        border.width: 1
        radius: 6

        // Vertical (Left/Right) resize handle
        Rectangle {
            id: vResizeHandle
            visible: root.isVertical && root.docks.length > 0
            width: vMouse.containsMouse || vMouse.pressed ? root.handleSize : root.handleSize * 0.5
            height: parent.height
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            anchors.right: (root.position === Enums.DockPosition.Left) ? parent.right : undefined
            anchors.left: (root.position === Enums.DockPosition.Right) ? parent.left : undefined
            color: "#c9c9c9"
            radius: parent.radius
            z: 10

            MouseArea {
                id: vMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeHorCursor
                property real startX
                property real startSize

                onPressed: function(m) {
                    startX = m.x
                    startSize = root.preferredSize
                }

                onPositionChanged: function(m) {
                    if (!pressed)
                        return

                    var delta = m.x - startX
                    if (root.position === Enums.DockPosition.Right)
                        delta = -delta

                    root.preferredSize = Math.max(root.minPreferredSize, Math.min(root.maxPreferredSize, startSize + delta))
                }
            }
        }

        // Horizontal (Top/Bottom) resize handle
        Rectangle {
            id: hResizeHandle
            visible: !root.isVertical && root.docks.length > 0
            width: parent.width
            height: hMouse.containsMouse || hMouse.pressed ? root.handleSize : root.handleSize * 0.5
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: (root.position === Enums.DockPosition.Top) ? parent.bottom : undefined
            anchors.top: (root.position === Enums.DockPosition.Bottom) ? parent.top : undefined
            color: "#c9c9c9"
            radius: parent.radius
            z: 10

            MouseArea {
                id: hMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.SizeVerCursor
                property real startY
                property real startSize

                onPressed: function(m) {
                    startY = m.y
                    startSize = root.preferredSize
                }

                onPositionChanged: function(m) {
                    if (!pressed)
                        return

                    var delta = m.y - startY
                    if (root.position === Enums.DockPosition.Bottom)
                        delta = -delta

                    root.preferredSize = Math.max(root.minPreferredSize, Math.min(root.maxPreferredSize, startSize + delta))
                }
            }
        }

        // Single dock - no tabs
        Item {
            id: singleDockContainer
            anchors.fill: parent
            visible: root.docks.length === 1

            Component.onCompleted: {
                singleDockContainer.setupSingleDock()
            }

            Connections {
                target: root
                function onDocksChanged() {
                    singleDockContainer.setupSingleDock()
                }
            }

            function setupSingleDock() {
                if (root.docks.length === 1 && root.docks[0]) {
                    var dock = root.docks[0]

                    // Clear all anchors and parent first
                    dock.anchors.fill = undefined
                    dock.anchors.left = undefined
                    dock.anchors.right = undefined
                    dock.anchors.top = undefined
                    dock.anchors.bottom = undefined
                    dock.parent = singleDockContainer
                    dock.anchors.fill = singleDockContainer

                    dock.isFloating = false
                    dock.visible = true
                }
            }
        }

        // Multiple docks - show tabs
        Column {
            anchors.fill: parent
            visible: root.docks.length > 1

            // Tab bar
            Rectangle {
                width: parent.width
                height: 25
                Row {
                    anchors.fill: parent
                    anchors.leftMargin: 5
                    spacing: 2

                    Repeater {
                        model: root.docks

                        Rectangle {
                            property int rectWidth:
                                Math.min(100, (parent.width - 50) / Math.max(1, root.docks.length))

                            width: index === root.activeIndex ? rectWidth + 12 : rectWidth
                            height: 25
                            color: index === root.activeIndex ? Qt.darker("#F9F9F9", 1.1) : "transparent"
                            border.color: Qt.darker("#F9F9F9", 1.1)
                            border.width: index === root.activeIndex ? 0 : 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 4

                                Label {
                                    text: modelData ? modelData.title : ""
                                    color: "#000000"
                                    font.pixelSize: 11
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                anchors.rightMargin: 20
                                onClicked: root.activeIndex = index
                                z: -1
                            }
                        }
                    }
                }
            }

            // Content area
            Item {
                width: parent.width
                height: parent.height - 25
                anchors.margins: 2

                Repeater {
                    model: root.docks

                    Item {
                        anchors.fill: parent
                        anchors.margins: 2
                        visible: index === root.activeIndex

                        Component.onCompleted: {
                            setupDock()
                        }

                        Connections {
                            target: root
                            function onActiveIndexChanged() {
                                setupDock()
                            }
                        }

                        function setupDock() {
                            if (!modelData) return

                            if (index === root.activeIndex) {

                                // Clear all anchors and parent first
                                modelData.anchors.fill = undefined
                                modelData.anchors.left = undefined
                                modelData.anchors.right = undefined
                                modelData.anchors.top = undefined
                                modelData.anchors.bottom = undefined

                                // Set new parent and anchors
                                modelData.parent = parent
                                modelData.anchors.fill = parent
                                modelData.visible = true
                                modelData.isFloating = false

                            } else {
                                modelData.visible = false
                            }
                        }
                    }
                }
            }
        }
    }
}
