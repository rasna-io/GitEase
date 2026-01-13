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
    property int activePosition: -1

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
                containsDrag: root.activePosition === Enums.DockPosition.Left
            }

            DropZoneIndicator {
                x: parent.width - root.defaultWidth
                y: 0
                width: root.defaultWidth
                height: parent.height
                position: Enums.DockPosition.Right
                label: "Right"
                icon: "▶"
                containsDrag: root.activePosition === Enums.DockPosition.Right
            }

            DropZoneIndicator {
                x: 0
                y: 0
                width: parent.width
                height: root.defaultHeight
                position: Enums.DockPosition.Top
                label: "Top"
                icon: "▲"
                containsDrag: root.activePosition === Enums.DockPosition.Top
            }

            DropZoneIndicator {
                x: 0
                y: parent.height - root.defaultHeight
                width: parent.width
                height: root.defaultHeight
                position: Enums.DockPosition.Bottom
                label: "Bottom"
                icon: "▼"
                containsDrag: root.activePosition === Enums.DockPosition.Bottom
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
