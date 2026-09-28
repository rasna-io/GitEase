import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * ReleaseBadge
 * Rounded pill with a short label, e.g. "Latest" or "3 feat".
 * ************************************************************************************************/
Rectangle {
    id: root

    property string label:     ""
    property color  textColor: Style.colors.pluginBadgeText
    property color  fillColor: Style.colors.pluginBadgeBackground
    property bool   strong:    false

    implicitHeight: Style.dp(20)
    implicitWidth: badgeText.implicitWidth + Style.dp(14)
    radius: height / 2
    color: fillColor
    border.width: strong ? 0 : 1
    border.color: Style.colors.pluginBadgeBorder

    Text {
        id: badgeText
        anchors.centerIn: parent
        text: root.label
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.microPt
        font.weight: root.strong ? Font.Bold : Font.Medium
        color: root.textColor
    }
}
