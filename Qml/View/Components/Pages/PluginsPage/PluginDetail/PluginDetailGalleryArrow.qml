import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailGalleryArrow
 * Round previous/next button placed over the screenshot preview.
 * ************************************************************************************************/
Button {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string iconText: ""

    /* Object Properties
     * ****************************************************************************************/
    width: Style.dp(34)
    height: Style.dp(34)
    hoverEnabled: true
    opacity: root.hovered ? 1.0 : 0.85

    background: Rectangle {
        radius: width / 2
        color: root.hovered ? Qt.rgba(0, 0, 0, 0.65) : Qt.rgba(0, 0, 0, 0.45)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.18)
    }

    contentItem: Text {
        text: root.iconText
        font.family: Style.fontTypes.font6Pro
        font.styleName: "Solid"
        font.pixelSize: Style.appFont.captionPt
        color: "white"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
