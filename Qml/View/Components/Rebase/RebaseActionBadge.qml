import QtQuick

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * RebaseActionBadge
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string action: RebaseActions.pick
    property int    count:  0

    readonly property color accentColor: RebaseActions.colorOf(root.action)

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: label.implicitWidth + 16
    implicitHeight: Style.dp(20)
    radius: 4

    color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.14)
    border.width: 1
    border.color: Qt.rgba(root.accentColor.r, root.accentColor.g, root.accentColor.b, 0.45)

    /* Children
     * ****************************************************************************************/
    Text {
        id: label
        anchors.centerIn: parent
        text: `${root.action}: ${root.count}`
        color: root.accentColor
        font.family: Style.fontTypes.jetBrainsMono
        font.pixelSize: Style.appFont.captionPt
    }
}
