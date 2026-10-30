import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import "qrc:/GitEase/Qml/Core/Scripts/PluginDetailFormat.js" as Format

/*! ***********************************************************************************************
 * PluginDetailFeatureGrid
 * Full feature list.
 * ************************************************************************************************/
GridLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var   features: []
    property color tint: Style.colors.accent

    /* Object Properties
     * ****************************************************************************************/
    Layout.fillWidth: true
    columns: root.width > Style.dp(560) ? 2 : 1
    columnSpacing: Style.dp(12)
    rowSpacing: Style.dp(12)

    /* Children
     * ****************************************************************************************/
    Repeater {
        model: root.features

        delegate: Rectangle {
            id: featureCard

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: 1
            implicitHeight: featureRow.implicitHeight + Style.dp(28)
            radius: Style.dp(10)
            color: Style.colors.pluginCardBackground
            border.width: 1
            border.color: Style.colors.pluginCardBorder

            RowLayout {
                id: featureRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: Style.dp(14)
                spacing: Style.dp(12)

                Rectangle {
                    Layout.alignment: Qt.AlignTop
                    Layout.preferredWidth: Style.dp(28)
                    Layout.preferredHeight: Style.dp(28)
                    radius: Style.dp(8)
                    color: Format.withAlpha(root.tint, 0.10)

                    Text {
                        anchors.centerIn: parent
                        text: Style.icons.check
                        font.family: Style.fontTypes.font6Pro
                        font.styleName: "Solid"
                        font.pixelSize: Style.appFont.captionPt
                        color: root.tint
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(4)

                    Label {
                        Layout.fillWidth: true
                        text: Format.featureTitle(modelData)
                        color: Style.colors.pluginCardTitle
                        font.pixelSize: Style.appFont.mediumPt
                        font.weight: Format.featureDescription(modelData) !== "" ? Font.DemiBold : Font.Normal
                        font.family: Style.fontTypes.inter
                        wrapMode: Text.WordWrap
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: Format.featureDescription(modelData)
                        color: Style.colors.pluginCardDescription
                        font.pixelSize: Style.appFont.smallPt
                        font.family: Style.fontTypes.inter
                        wrapMode: Text.WordWrap
                        lineHeight: 1.4
                        lineHeightMode: Text.ProportionalHeight
                    }
                }
            }
        }
    }
}
