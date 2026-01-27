import QtQuick
import QtQuick.Controls

import GitEase_Style

/*! ***********************************************************************************************
 * ActionIconButton
 * Compact icon button used in file list rows.
 * - Customizable text, background, and border colors
 * - Styled tooltip
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string iconText: ""
    property string tooltip: ""
    
    // Customizable colors with default values
    property color textColor: Style.colors.secondaryText
    property color backgroundColor: "transparent"
    property color borderColor: "transparent"
    property real  borderWidth: 0

    /* Object Properties
     * ****************************************************************************************/
    width: 20
    height: 20
    radius: 4

    property color hoverBackgroundColor: {
        if (backgroundColor == "transparent" || Qt.colorEqual(backgroundColor, "transparent")) {
            return Style.colors.surfaceMuted
        }
        return Style.theme == Style.Light ? Qt.darker(backgroundColor, 1.2) : Qt.lighter(backgroundColor, 1.3)
    }

    property color hoverTextColor: Style.theme == Style.Light ? Qt.darker(textColor, 1.2) : Qt.lighter(textColor, 1.3)
    
    property color hoverBorderColor: {
        if (borderColor == "transparent" || Qt.colorEqual(borderColor, "transparent")) {
            return "transparent"
        }
        return Style.theme == Style.Light ? Qt.darker(borderColor, 1.2) : Qt.lighter(borderColor, 1.3)
    }

    color: mouse.containsMouse ? root.hoverBackgroundColor : root.backgroundColor
    border.color: mouse.containsMouse ? root.hoverBorderColor : root.borderColor
    border.width: root.borderWidth

    /* Signals
     * ****************************************************************************************/
    signal clicked()

    /* Children
     * ****************************************************************************************/
    Text {
        anchors.centerIn: parent
        text: root.iconText
        font.family: Style.fontTypes.font6ProSolid
        font.pixelSize: 11
        color: mouse.containsMouse ? root.hoverTextColor : root.textColor
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }

    ToolTip {
        id: tip
        parent: root
        visible: mouse.containsMouse && root.tooltip !== ""
        delay: 100
        timeout: 2000
        text: root.tooltip

        x: (root.width - width) / 2
        y: -height - 6

        padding: 6

        contentItem: Text {
            text: tip.text
            font.family: Style.fontTypes.roboto
            font.pixelSize: 11
            color: "#ffffff"
        }

        background: Rectangle {
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.85)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
        }
    }
}
