import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ProgressButtone
 * ************************************************************************************************/
Button {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool busy: false
    property real progress: 0
    property string idleText: "Continue"

    /* Object Properties
     * ****************************************************************************************/
    flat: false
    Material.background: Style.colors.accent
    Material.foreground: "white"

    text: busy ? (Math.round(progress) + " %") : idleText

    background: Rectangle {
        radius: 3
        color: root.enabled
               ? (root.hovered ? Style.colors.accentHover : Style.colors.accent)
               : Style.colors.disabledButton

        // Progress overlay while busy
        Rectangle {
            anchors.fill: parent
            visible: root.busy
            color: "#CCCCCC"
            radius: 3

            Rectangle {
                width: parent.width * (root.progress / 100.0)
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                color: Style.colors.accent
                radius: 3
                Behavior on width { NumberAnimation { duration: 100 } }
            }
        }

        Behavior on color { ColorAnimation { duration: 150 } }
    }
}
