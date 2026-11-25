import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * SkeletonBone
 * Soft shimmer bar used to build skeleton placeholders while content loads.
 * ************************************************************************************************/
Rectangle {
    id: root

    property bool running: true
    property color baseColor: Style.colors.pluginCardBorder
    property color highlightColor: Style.colors.pluginCardBackground

    radius: Style.dp(6)
    clip: true
    color: root.baseColor
    opacity: 0.55

    SequentialAnimation on opacity {
        running: root.running && root.visible
        loops: Animation.Infinite
        NumberAnimation {
            to: 0.35
            duration: 780
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            to: 0.7
            duration: 780
            easing.type: Easing.InOutSine
        }
    }

    Rectangle {
        id: sheen
        width: Math.max(Style.dp(48), root.width * 0.38)
        height: parent.height * 1.6
        anchors.verticalCenter: parent.verticalCenter
        rotation: 18
        opacity: 0.55
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.45; color: root.highlightColor }
            GradientStop { position: 1.0; color: "transparent" }
        }

        SequentialAnimation on x {
            running: root.running && root.visible
            loops: Animation.Infinite
            NumberAnimation {
                from: -sheen.width
                to: root.width + sheen.width
                duration: 1400
                easing.type: Easing.InOutCubic
            }
            PauseAnimation { duration: 320 }
        }
    }
}
