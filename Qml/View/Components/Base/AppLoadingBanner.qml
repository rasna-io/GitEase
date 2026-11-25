import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style

/*! ***********************************************************************************************
 * AppLoadingBanner
 * Compact top-of-content chip shown while background work (plugins, etc.) is still running.
 * ************************************************************************************************/
Item {
    id: root

    property bool   running: false
    property string message: "Loading"
    property int    pendingCount: 0

    implicitHeight: visible ? Style.dp(34) : 0
    visible: root.running
    clip: true

    Behavior on implicitHeight {
        NumberAnimation {
            duration: 180
            easing.type: Easing.OutCubic
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: Style.dp(8)
        color: Style.colors.pluginCardBackground
        border.width: 1
        border.color: Style.colors.pluginCardBorder

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Style.dp(12)
            anchors.rightMargin: Style.dp(12)
            spacing: Style.dp(10)

            BusyIndicator {
                Layout.preferredWidth: Style.dp(16)
                Layout.preferredHeight: Style.dp(16)
                running: root.running
                Material.accent: Style.colors.accent
            }

            Label {
                Layout.fillWidth: true
                text: root.pendingCount > 0
                      ? (root.message + " (" + root.pendingCount + ")")
                      : root.message
                color: Style.colors.pluginCardMetaText
                font.pixelSize: Style.appFont.smallPt
                font.family: Style.fontTypes.inter
                elide: Text.ElideRight
            }

            SkeletonBone {
                Layout.preferredWidth: Style.dp(72)
                Layout.preferredHeight: Style.dp(8)
                running: root.running
            }
        }
    }
}
