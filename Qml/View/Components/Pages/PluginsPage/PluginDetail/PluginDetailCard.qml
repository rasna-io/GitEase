import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * PluginDetailCard
 * Titled card that hosts a section of the plugin details. Children are placed in the card body.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title: ""
    property string iconText: ""
    property color  tint: Style.colors.pluginSectionLabel
    property string trailing: ""

    default property alias content: cardBody.data

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    radius: Style.dp(12)
    color: Style.colors.pluginCardBackground
    border.width: 1
    border.color: Style.colors.pluginCardBorder
    implicitHeight: cardColumn.implicitHeight + Style.dp(34)

    /* Children
     * ****************************************************************************************/

    ColumnLayout {
        id: cardColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: Style.dp(17)
        spacing: Style.dp(14)

        RowLayout {
            visible: root.title !== ""
            Layout.fillWidth: true
            spacing: Style.dp(8)

            Text {
                visible: root.iconText !== ""
                text: root.iconText
                font.family: Style.fontTypes.font6Pro
                font.styleName: "Solid"
                font.pixelSize: Style.appFont.captionPt
                color: root.tint
            }

            Label {
                text: root.title
                color: Style.colors.pluginCardTitle
                font.pixelSize: Style.appFont.h4Pt
                font.weight: Font.DemiBold
                font.family: Style.fontTypes.inter
            }

            Item {
                Layout.fillWidth: true
            }

            Label {
                visible: root.trailing !== ""
                text: root.trailing
                color: Style.colors.pluginCardMetaText
                font.pixelSize: Style.appFont.smallPt
                font.family: Style.fontTypes.jetBrainsMono
            }
        }

        ColumnLayout {
            id: cardBody
            Layout.fillWidth: true
            spacing: Style.dp(10)
        }
    }
}
