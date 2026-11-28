import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RepoBrowseButton
 * Outlined secondary button used for Browse / Open actions.
 * ************************************************************************************************/
Button {
    id: root

    Layout.alignment: Qt.AlignVCenter
    implicitHeight: 43
    implicitWidth: 74
    flat: true
    text: "Browse"
    font.family: Style.fontTypes.inter
    font.pixelSize: 12

    scale: root.pressed ? 0.96 : 1.0

    Behavior on scale {
        NumberAnimation {
            duration: Style.motionFast
            easing.type: Easing.OutCubic
        }
    }

    background: Rectangle {
        radius: 6
        color: root.hovered ? Style.colors.controlBackgroundHover : Style.colors.controlBackground
        border.width: 1
        border.color: root.hovered ? Style.colors.accent : Style.colors.controlBorder
        Behavior on border.color {
            ColorAnimation {
                duration: Style.motionFast
                easing.type: Easing.OutCubic
            }
        }
    }

    contentItem: Text {
        text: root.text
        font: root.font
        color: Style.colors.foreground
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
    }
}
