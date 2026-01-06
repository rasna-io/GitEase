import QtQuick
import QtQuick.Controls

import GitEase_Style

/*! ***********************************************************************************************
 * ActionIconButton
 * Compact icon button used in file list rows.
 * - Enum role controls icon + hover colors
 * - Styled tooltip
 * ************************************************************************************************/

Rectangle {
    id: root

    /* Enums
     * ****************************************************************************************/
    enum Role {Stage, Unstage, Discard, Open, Stash}

    /* Property Declarations
     * ****************************************************************************************/
    property int role: ActionIconButton.Role.Open
    property string iconText: ""
    property string tooltip: ""

    /* Object Properties
     * ****************************************************************************************/
    width: 20
    height: 20
    radius: 4

    readonly property color hoverBg: Style.colors.surfaceMuted

    readonly property color iconColor: (function() {
        switch (root.role) {
            case ActionIconButton.Role.Stage:
                return Qt.darker(Style.colors.addedFile, 1.5)
            case ActionIconButton.Role.Unstage:
                return Style.colors.accent
            case ActionIconButton.Role.Discard:
                return Style.colors.error
            case ActionIconButton.Role.Stash:
                return Style.colors.mutedText
            case ActionIconButton.Role.Open:
            default:
                return Style.colors.secondaryText
        }
    })()

    color: mouse.containsMouse ? root.hoverBg : "transparent"

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
        color: root.iconColor
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
