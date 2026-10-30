import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailInfoRow
 * Icon, label and right aligned value row used by the details card.
 * ************************************************************************************************/
RowLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string iconText: ""
    property string label: ""
    property string value: ""
    property bool   mono: false

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    spacing: Style.dp(10)

    /* Children
     * ****************************************************************************************/
    Text {
        Layout.preferredWidth: Style.dp(16)
        text: root.iconText
        font.family: Style.fontTypes.font6Pro
        font.styleName: "Solid"
        font.pixelSize: Style.appFont.captionPt
        color: Style.colors.pluginCardMetaText
        horizontalAlignment: Text.AlignHCenter
    }

    Label {
        Layout.fillWidth: true
        text: root.label
        color: Style.colors.pluginCardDescription
        font.pixelSize: Style.appFont.smallPt
        font.family: Style.fontTypes.inter
    }

    // Fixed cap: tying this to the row's own width makes the layout rearrange recursively
    Label {
        Layout.maximumWidth: Style.dp(170)
        text: root.value
        color: Style.colors.pluginCardTitle
        font.pixelSize: Style.appFont.smallPt
        font.weight: Font.DemiBold
        font.family: root.mono ? Style.fontTypes.jetBrainsMono : Style.fontTypes.inter
        horizontalAlignment: Text.AlignRight
        elide: Text.ElideRight
    }
}
