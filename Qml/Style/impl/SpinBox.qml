import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts

import GitEase_Style

T.SpinBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             up.implicitIndicatorHeight, down.implicitIndicatorHeight)

    spacing: 4
    leftPadding: (control.mirrored ? (up.indicator ? up.indicator.width : 0) : (down.indicator ? down.indicator.width : 0)) + spacing
    rightPadding: (control.mirrored ? (down.indicator ? down.indicator.width : 0) : (up.indicator ? up.indicator.width : 0)) + spacing

    validator: IntValidator {
        locale: control.locale.name
        bottom: Math.min(control.from, control.to)
        top: Math.max(control.from, control.to)
    }

    // Content item (value display in the center)
    contentItem: Item {
        implicitWidth: 60
        
        TextInput {
            anchors.fill: parent
            anchors.leftMargin: control.spacing
            anchors.rightMargin: control.spacing
            z: 2
            text: control.displayText
            opacity: control.enabled ? 1 : 0.3
            color: Style.colors.foreground
            selectionColor: Style.colors.accent
            selectedTextColor: Style.colors.secondaryForeground
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
            readOnly: !control.editable
            validator: control.validator
            inputMethodHints: control.inputMethodHints
            font.pointSize: Style.appFont.h4Pt

            Rectangle {
                anchors.fill: parent
                z: -1
                radius: 4
                color: Style.colors.primaryBackground
                border.width: 1
                border.color: Style.colors.primaryBorder
            }
        }
    }

    // Decrease button (left)
    down.indicator: Rectangle {
        x: control.mirrored ? parent.width - width - control.spacing : control.spacing
        height: parent.height
        implicitWidth: 36
        implicitHeight: 36
        radius: 4
        color: control.down.pressed ? Style.colors.accent : Style.colors.primaryBackground
        border.width: 1
        border.color: Style.colors.primaryBorder

        Text {
            anchors.centerIn: parent
            text: Style.icons.minus
            font.family: Style.fontTypes.font6ProSolid
            font.pixelSize: 14
            color: control.down.pressed ? Style.colors.secondaryForeground : Style.colors.foreground
            opacity: control.down.indicator.enabled ? 1 : 0.3
        }
    }

    // Increase button (right)
    up.indicator: Rectangle {
        x: control.mirrored ? control.spacing : parent.width - width - control.spacing
        height: parent.height
        implicitWidth: 36
        implicitHeight: 36
        radius: 4
        color: control.up.pressed ? Style.colors.accent : Style.colors.primaryBackground
        border.width: 1
        border.color: Style.colors.primaryBorder

        Text {
            anchors.centerIn: parent
            text: Style.icons.plus
            font.family: Style.fontTypes.font6ProSolid
            font.pixelSize: 14
            color: control.up.pressed ? Style.colors.secondaryForeground : Style.colors.foreground
            opacity: control.up.indicator.enabled ? 1 : 0.3
        }
    }

    background: Rectangle {
        implicitWidth: 128
        color: "transparent"
    }
}
