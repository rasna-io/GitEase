import QtQuick
import QtQuick.Controls

import GitEase_Style

/*! ***********************************************************************************************
 * ReleaseButton
 * Button used across the release page. variant: "primary", "secondary" or "ghost".
 * ************************************************************************************************/
AbstractButton {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string variant:  "secondary"
    property string iconText: ""
    property string tooltip:  ""
    property bool   large:    false

    readonly property bool primary: variant === "primary"
    readonly property bool ghost:   variant === "ghost"

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: large ? Style.dp(38) : Style.dp(28)
    implicitWidth: buttonRow.implicitWidth + (large ? Style.dp(32) : Style.dp(18))
    hoverEnabled: true
    opacity: enabled ? 1.0 : 0.45

    ToolTip.visible: hovered && tooltip.length > 0
    ToolTip.delay: 500
    ToolTip.text: tooltip

    background: Rectangle {
        radius: root.large ? Style.dp(8) : Style.dp(6)
        color: root.primary ? (root.down ? Qt.darker(Style.colors.accent, 1.1)
                                         : root.hovered ? Qt.lighter(Style.colors.accent, 1.1) : Style.colors.accent)
             : root.ghost   ? (root.hovered ? Style.colors.controlBackgroundHover : "transparent")
             : (root.hovered ? Style.colors.controlBackgroundHover : Style.colors.controlBackground)
        border.width: root.primary || root.ghost ? 0 : 1
        border.color: Style.colors.controlBorder

        Behavior on color { ColorAnimation { duration: Style.motionFast } }
    }

    contentItem: Item {
        Row {
            id: buttonRow
            anchors.centerIn: parent
            spacing: Style.dp(6)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.iconText.length > 0
                text: root.iconText
                font.family: Style.fontTypes.font6Pro
                font.pixelSize: root.large ? Style.appFont.captionPt : Style.appFont.microPt
                color: root.primary ? Style.colors.onAccentText : root.ghost ? Style.colors.accent : Style.colors.foreground
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.text.length > 0
                text: root.text
                font.family: Style.fontTypes.inter
                font.pixelSize: root.large ? Style.appFont.smallPt : Style.appFont.captionPt
                font.weight: root.primary ? Font.DemiBold : Font.Medium
                color: root.primary ? Style.colors.onAccentText : root.ghost ? Style.colors.accent : Style.colors.foreground
            }
        }
    }

    HoverHandler { cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
}
