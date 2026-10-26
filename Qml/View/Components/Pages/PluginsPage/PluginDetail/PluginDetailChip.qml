import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailChip
 * Small rounded label with an optional icon, tinted by a single colour.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string text: ""
    property string iconText: ""
    property color  tint: Style.colors.accent
    property bool   mono: false

    /* Object Properties
     * ****************************************************************************************/
    radius: height / 2
    color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.10)
    border.width: 1
    border.color: Qt.rgba(root.tint.r, root.tint.g, root.tint.b, 0.26)
    implicitHeight: chipRow.implicitHeight + Style.dp(6)
    implicitWidth: chipRow.implicitWidth + Style.dp(18)

    /* Children
     * ****************************************************************************************/
    Row {
        id: chipRow
        anchors.centerIn: parent
        spacing: Style.dp(5)

        Text {
            visible: root.iconText !== ""
            anchors.verticalCenter: parent.verticalCenter
            text: root.iconText
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.captionPt
            color: root.tint
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.tint
            font.pixelSize: Style.appFont.smallPt
            font.weight: Font.DemiBold
            font.family: root.mono ? Style.fontTypes.jetBrainsMono : Style.fontTypes.inter
        }
    }
}
