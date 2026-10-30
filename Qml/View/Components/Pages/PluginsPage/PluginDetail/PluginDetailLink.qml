import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailLink
 * Text link with a trailing arrow that nudges forward on hover.
 * ************************************************************************************************/
Item {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string text: ""
    property string iconText: ""
    property color  tint: Style.colors.accent

    /* Signals
     * ****************************************************************************************/
    signal clicked()

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: linkRow.implicitWidth + Style.dp(4)
    implicitHeight: linkRow.implicitHeight + Style.dp(4)

    /* Children
     * ****************************************************************************************/
    Row {
        id: linkRow
        anchors.verticalCenter: parent.verticalCenter
        spacing: Style.dp(7)

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
            font.weight: Font.Medium
            font.family: Style.fontTypes.inter
            font.underline: linkHover.hovered
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: Style.icons.arrowRight
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.microPt
            color: root.tint
        }
    }

    HoverHandler {
        id: linkHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.clicked()
    }
}
