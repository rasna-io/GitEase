import QtQuick
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

T.TabButton {
    id: control

    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 12
    spacing: 6

    icon.width: 24
    icon.height: 24
    icon.color: !enabled ? Material.hintTextColor : down || checked ? Material.accentColor : Material.foreground

    contentItem: IconLabel {
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display

        icon: control.icon
        text: control.text
        font: control.font
        color: !control.enabled ? control.Material.hintTextColor : control.down || control.checked ? control.Material.accentColor : control.Material.foreground
    }

    background: Ripple {
        implicitHeight: control.Material.touchTarget

        clip: true
        pressed: control.pressed
        anchor: control
        active: enabled && (control.down || control.visualFocus || control.hovered)
        color: control.Material.rippleColor
    }

    /* Animations
     * ****************************************************************************************/
    states: [
        State {
            name: "pressed"
            PropertyChanges {
                target: control
                scale: 0.8
            }
        }
    ]

    transitions: [
        Transition {
            from: ""
            to: "pressed"
            NumberAnimation { properties: "scale"; duration: 100}
        },
        Transition {
            from: "pressed"
            to: ""
            NumberAnimation {
                properties: "scale";
                duration: 200;
                easing.type: Easing.OutElastic;
                easing.amplitude: 0.6
            }
        }
    ]

    onPressed: state = "pressed"
    onReleased: state = ""
    onCanceled: state = ""
}
