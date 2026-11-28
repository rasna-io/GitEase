import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * ConflictRegionLabel
 * Heads the "ours" or "theirs" half of a conflict card, naming the branch or commit the lines below
 * came from.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property alias text:        label.text
    property color labelColor:  Style.colors.foreground
    property color tintColor:   "transparent"

    /* Object Properties
     * ****************************************************************************************/
    color: root.tintColor

    /* Children
     * ****************************************************************************************/
    Text {
        id: label
        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        color: root.labelColor
        font.family: Style.fontTypes.jetBrainsMono
        font.weight: Font.DemiBold
        font.letterSpacing: 0.6
        font.pixelSize: Style.appFont.microPt
    }
}
