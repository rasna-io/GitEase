import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailMetaItem
 * Icon followed by a short piece of metadata (author, downloads, release date).
 * ************************************************************************************************/
Row {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string iconText: ""
    property string text: ""

    /* Object Properties
     * ****************************************************************************************/
    spacing: Style.dp(6)

    /* Children
     * ****************************************************************************************/
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: root.iconText
        font.family: Style.fontTypes.font6Pro
        font.styleName: "Solid"
        font.pixelSize: Style.appFont.captionPt
        color: Style.colors.pluginCardMetaText
    }

    Label {
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        color: Style.colors.pluginSectionLabel
        font.pixelSize: Style.appFont.smallPt
        font.family: Style.fontTypes.inter
    }
}
