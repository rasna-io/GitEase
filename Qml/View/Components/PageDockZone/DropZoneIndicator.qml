import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * DropZoneIndicator
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool containsDrag: false
    property int position: Enums.DockPosition.Left
    property string label: "Left"
    property string icon: "◀"

    /* Object Properties
     * ****************************************************************************************/
    color: root.containsDrag ? "#11005a9e" : "#005a9e20"
    border.color: "#00a4ff"
    border.width: root.containsDrag ? 1 : 0
    radius: 4
    opacity: root.containsDrag ? 0.95 : 0.6

    /* Children
     * ****************************************************************************************/
    Behavior on opacity {
        NumberAnimation {
            duration: 150;
            easing.type: Easing.OutCubic
        }
    }

    Behavior on border.width {
        NumberAnimation {
            duration: 150;
            easing.type: Easing.OutCubic
        }
    }

    // Content based on position
    Loader {
        anchors.centerIn: parent
        sourceComponent: (root.position === Enums.DockPosition.Left ||
                          root.position === Enums.DockPosition.Right)
                         ? verticalContent : horizontalContent
    }

    Component {
        id: verticalContent
        Column {
            spacing: 8
            opacity: root.containsDrag ? 1.0 : 0.7

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Text {
                text: root.icon
                font.pixelSize: 36
                font.weight: Font.Bold
                color: Style.colors.titleText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                text: root.label
                color: Style.colors.titleText
                font.bold: true
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Component {
        id: horizontalContent
        Row {
            spacing: 8
            opacity: root.containsDrag ? 1.0 : 0.7

            Behavior on opacity {
                NumberAnimation {
                    duration: 150
                }
            }

            Text {
                text: root.icon
                font.pixelSize: 36
                font.weight: Font.Bold
                color: Style.colors.titleText
                anchors.verticalCenter: parent.verticalCenter
            }

            Label {
                text: root.label
                color: Style.colors.titleText
                font.bold: true
                font.pixelSize: 13
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }
}

