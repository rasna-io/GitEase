import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailButton
 * Filled or outlined action button for the hero header.
 * ************************************************************************************************/
Button {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string iconText: ""
    property string label: ""
    property color  fill: Style.colors.accent
    property color  fillHover: Style.colors.accentHover
    property color  textColor: Style.colors.onAccentText
    property bool   outlined: false
    property color  hoverTint: Style.colors.accent

    readonly property color foreground: root.outlined && root.hovered && root.enabled ? root.hoverTint
                                                                                      : root.textColor

    /* Object Properties
     * ****************************************************************************************/
    hoverEnabled: true
    topInset: 0
    bottomInset: 0
    leftInset: 0
    rightInset: 0
    topPadding: Style.dp(9)
    bottomPadding: Style.dp(9)
    leftPadding: Style.dp(16)
    rightPadding: Style.dp(16)
    opacity: root.enabled ? 1.0 : 0.55

    background: Rectangle {
        radius: Style.dp(8)
        color: root.outlined
               ? (root.hovered && root.enabled ? Qt.rgba(root.hoverTint.r, root.hoverTint.g,
                                                         root.hoverTint.b, 0.10)
                                               : "transparent")
               : (!root.enabled ? Style.colors.disabledButton
                                : (root.hovered ? root.fillHover : root.fill))
        border.width: root.outlined ? 1 : 0
        border.color: root.outlined && root.hovered && root.enabled ? root.hoverTint
                                                                    : Style.colors.pluginBtnSecondaryBorder

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    contentItem: Row {
        spacing: Style.dp(8)

        Text {
            visible: root.iconText !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.iconText
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.captionPt
            color: root.foreground
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: root.foreground
            font.pixelSize: Style.appFont.mediumPt
            font.weight: Font.DemiBold
            font.family: Style.fontTypes.inter
        }
    }
}
