import QtQuick
import QtQuick.Controls

import GitEase
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * PageDropZone
 * Page Drop Zone conatin Drop Zone Indicators
 * ************************************************************************************************/

Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property real defaultWidth: 300
    property real defaultHeight: 180

    /* Children
     * ****************************************************************************************/
    Rectangle {
        anchors.fill: parent

        Item {
            anchors.fill: parent

            DropZoneIndicator {
                x: 0
                y: 0
                width: root.defaultWidth
                height: parent.height
                position: Enums.DockPosition.Left
                label: "Left"
                icon: "◀"
                containsDrag: leftDropArea.containsDrag
            }

            MouseArea {
                id: leftDropArea
                x: 0
                y: 0
                width: root.defaultWidth
                height: parent.height
                property bool containsDrag: false
                hoverEnabled: true

                onEntered: {
                    containsDrag = true
                }
                onExited: {
                    containsDrag = false
                }
            }

            DropZoneIndicator {
                x: parent.width - root.defaultWidth
                y: 0
                width: root.defaultWidth
                height: parent.height
                position: Enums.DockPosition.Right
                label: "Right"
                icon: "▶"
                containsDrag: rightDropArea.containsDrag
            }

            MouseArea {
                id: rightDropArea
                x: parent.width - root.defaultWidth
                y: 0
                width: root.defaultWidth
                height: parent.height
                property bool containsDrag: false
                hoverEnabled: true

                onEntered: {
                    containsDrag = true
                }
                onExited: {
                    containsDrag = false
                }
            }

            DropZoneIndicator {
                x: 0
                y: 0
                width: parent.width
                height: root.defaultHeight
                position: Enums.DockPosition.Top
                label: "Top"
                icon: "▲"
                containsDrag: topDropArea.containsDrag
            }

            MouseArea {
                id: topDropArea
                x: 0
                y: 0
                width: parent.width
                height: root.defaultHeight
                property bool containsDrag: false
                hoverEnabled: true

                onEntered: {
                    containsDrag = true
                }
                onExited: {
                    containsDrag = false
                }
            }

            DropZoneIndicator {
                x: 0
                y: parent.height - root.defaultHeight
                width: parent.width
                height: root.defaultHeight
                position: Enums.DockPosition.Bottom
                label: "Bottom"
                icon: "▼"
                containsDrag: bottomDropArea.containsDrag
            }

            MouseArea {
                id: bottomDropArea
                x: 0
                y: parent.height - root.defaultHeight
                width: parent.width
                height: root.defaultHeight
                property bool containsDrag: false
                hoverEnabled: true

                onEntered: {
                    containsDrag = true
                }
                onExited: {
                    containsDrag = false
                }
            }

            Frame {
                id: instructionFrame
                anchors.centerIn: parent
                width: instructionText.width + 60
                height: instructionText.height + 30
                padding: 15
                opacity: 0.98

                Behavior on opacity {
                    NumberAnimation {
                        duration: 200;
                        easing.type: Easing.OutCubic
                    }
                }

                Label {
                    id: instructionText
                    anchors.centerIn: parent
                    text: "Drag to edge to dock • Release anywhere else to float"
                    color: "#000000"
                    font.bold: true
                    font.pixelSize: 13
                }
            }
        }
    }
}
