import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * PluginsSkeletonView
 * Marketplace loading placeholder: shimmer cards + status line.
 * ************************************************************************************************/
Item {
    id: root

    property bool   running: true
    property string message: "Loading plugins"
    property int    pendingCount: 0
    property int    minCardWidth: 280
    property int    minCardHeight: 170
    property int    placeholderCount: 6

    readonly property int columns: Math.max(1, Math.floor(width / root.minCardWidth))

    ColumnLayout {
        anchors.fill: parent
        spacing: Style.dp(12)

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.dp(10)

            BusyIndicator {
                Layout.preferredWidth: Style.dp(18)
                Layout.preferredHeight: Style.dp(18)
                running: root.running
                visible: root.running
                Material.accent: Style.colors.accent
            }

            Label {
                Layout.fillWidth: true
                text: root.pendingCount > 0
                      ? (root.message + " · " + root.pendingCount + " remaining")
                      : root.message
                color: Style.colors.pluginSectionMetaText
                font.pixelSize: Style.appFont.smallPt
                font.family: Style.fontTypes.inter
                elide: Text.ElideRight
            }
        }

        Grid {
            id: skeletonGrid
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: root.columns
            columnSpacing: 8
            rowSpacing: 8
            clip: true

            Repeater {
                model: root.placeholderCount

                Item {
                    width: Math.floor((skeletonGrid.width - (root.columns - 1) * skeletonGrid.columnSpacing)
                                      / root.columns)
                    height: root.minCardHeight

                    PluginCardSkeleton {
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: parent.height - 8
                        running: root.running
                    }
                }
            }
        }
    }
}
