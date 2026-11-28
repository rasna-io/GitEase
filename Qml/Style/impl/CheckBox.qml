import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

import GitEase
import GitEase_Style

T.CheckBox {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding,
                             implicitIndicatorWidth + leftPadding + rightPadding)

    spacing: 8
    padding: 4
    topPadding: 2
    bottomPadding: 2

    indicator: Rectangle {
        id: indicator
        x: control.mirrored ? control.width - width - control.rightPadding : control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 16
        height: 16
        radius: 3
        border.width: 1.5
        border.color: control.checked ? Style.colors.popupCheckboxBackgroundChecked : Style.colors.popupCheckboxBorder
        color: control.checked ? Style.colors.popupCheckboxBackgroundChecked : "transparent"

        Text {
            id: checkmark
            anchors.centerIn: parent
            text: Style.icons.check
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.mediumPt
            color: Style.colors.popupCheckboxCheckmark
            visible: control.checked
            opacity: control.checked ? 1 : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutQuad
                }
            }
        }

        Ripple {
            clip: true
            clipRadius: parent.radius
            width: parent.width * 1.5
            height: parent.height * 1.5
            anchors.centerIn: parent
            pressed: control.pressed
            active: control.enabled && (control.down || control.visualFocus || control.hovered)
            color: control.Material.rippleColor
        }
    }

    contentItem: Text {
        leftPadding: control.indicator ? control.indicator.width + control.spacing : 0
        rightPadding: control.mirrored && control.indicator ? control.indicator.width + control.spacing : 0

        text: control.text
        font: control.font
        color: control.enabled ? Style.colors.popupCheckboxLabelText : Style.colors.hintText
        elide: Text.ElideRight
        verticalAlignment: Text.AlignVCenter
    }

    onCheckedChanged: {
        indicator.color = control.checked ? Style.colors.popupCheckboxBackgroundChecked : "transparent"
        indicator.border.color = control.checked ? Style.colors.popupCheckboxBackgroundChecked : Style.colors.popupCheckboxBorder
    }
}