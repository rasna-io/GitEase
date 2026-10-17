import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * PatternModeTab
 * One entry of the segmented selector that chooses how a rule is written.
 * ************************************************************************************************/
Rectangle {
    id: root

    property string label:  ""
    property string tip:    ""
    property bool   active: false

    signal clicked()

    height: Style.dp(20)
    width: tabText.implicitWidth + Style.dp(16)
    radius: Style.dp(5)
    color: active ? Style.colors.accent
         : tabHover.hovered ? Style.colors.controlBackgroundHover : "transparent"

    HoverHandler {
        id: tabHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler { onTapped: root.clicked() }

    GitignoreToolTip {
        visible: tabHover.hovered
        text: root.tip
    }

    Text {
        id: tabText
        anchors.centerIn: parent
        text: root.label
        font.family: Style.fontTypes.inter
        font.pixelSize: Style.appFont.microPt
        font.weight: Font.Medium
        color: root.active ? Style.colors.onAccentText : Style.colors.secondaryText
    }
}
