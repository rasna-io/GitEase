import QtQuick
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * PluginCardSkeleton
 * Card-shaped skeleton matching PluginCard proportions.
 * ************************************************************************************************/
Rectangle {
    id: root

    property bool running: true

    color: Style.colors.pluginCardBackground
    radius: 7
    border.width: 1
    border.color: Style.colors.pluginCardBorder
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: Style.dp(14)
        spacing: Style.dp(10)

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.dp(12)

            SkeletonBone {
                Layout.preferredWidth: Style.dp(52)
                Layout.preferredHeight: Style.dp(52)
                radius: Style.dp(12)
                running: root.running
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Style.dp(6)

                SkeletonBone {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Style.dp(14)
                    Layout.maximumWidth: parent.width * 0.72
                    running: root.running
                }

                SkeletonBone {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Style.dp(10)
                    Layout.maximumWidth: parent.width * 0.42
                    running: root.running
                }
            }
        }

        SkeletonBone {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(10)
            running: root.running
        }

        SkeletonBone {
            Layout.fillWidth: true
            Layout.preferredHeight: Style.dp(10)
            Layout.maximumWidth: parent.width * 0.78
            running: root.running
        }

        Item { Layout.fillHeight: true }

        RowLayout {
            Layout.fillWidth: true
            spacing: Style.dp(8)

            SkeletonBone {
                Layout.preferredWidth: Style.dp(64)
                Layout.preferredHeight: Style.dp(22)
                radius: Style.dp(11)
                running: root.running
            }

            Item { Layout.fillWidth: true }

            SkeletonBone {
                Layout.preferredWidth: Style.dp(78)
                Layout.preferredHeight: Style.dp(28)
                radius: Style.dp(7)
                running: root.running
            }
        }
    }
}
