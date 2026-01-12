import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

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
