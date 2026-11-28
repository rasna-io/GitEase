import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase
import "qrc:/GitEase/Qml/Core/Scripts/PluginDetailFormat.js" as Format

/*! ***********************************************************************************************
 * PluginDetailChangelog
 * Version history rendered as a timeline.
 * ************************************************************************************************/
PluginDetailCard {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property var changelog: []

    /* Children
     * ****************************************************************************************/
    Repeater {
        id: entries
        model: root.changelog

        delegate: RowLayout {
            id: entry

            Layout.fillWidth: true
            spacing: Style.dp(14)

            // Timeline rail
            Item {
                Layout.preferredWidth: Style.dp(14)
                Layout.fillHeight: true

                Rectangle {
                    visible: index < entries.count - 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    anchors.topMargin: Style.dp(14)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: -Style.dp(12)
                    width: 2
                    color: Style.colors.pluginDivider
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Style.dp(4)
                    width: Style.dp(12)
                    height: width
                    radius: width / 2
                    color: index === 0 ? root.tint : Style.colors.pluginCardBackground
                    border.width: 2
                    border.color: index === 0 ? root.tint : Style.colors.pluginToggleTrackOffBorder
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.bottomMargin: index < entries.count - 1 ? Style.dp(14) : 0
                spacing: Style.dp(6)

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Style.dp(8)

                    Label {
                        text: "v" + (modelData.version || "")
                        color: Style.colors.pluginCardTitle
                        font.pixelSize: Style.appFont.mediumPt
                        font.weight: Font.DemiBold
                        font.family: Style.fontTypes.jetBrainsMono
                    }

                    PluginDetailChip {
                        visible: index === 0
                        text: "Latest"
                        tint: root.tint
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Label {
                        text: modelData.date || ""
                        color: Style.colors.pluginCardMetaText
                        font.pixelSize: Style.appFont.smallPt
                        font.family: Style.fontTypes.inter
                    }
                }

                PluginDetailRichText {
                    visible: text !== ""
                    text: Format.changeNotes(modelData)
                }
            }
        }
    }
}
