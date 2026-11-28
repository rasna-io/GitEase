import QtQuick
import QtQuick.Templates as T

import GitEase_Style

/*! ***********************************************************************************************
 * ScrollBar
 * ************************************************************************************************/
T.ScrollBar {
    id: control

    /* Property Declarations
     * ****************************************************************************************/
    property real restThickness:   4
    property real activeThickness: 9
    property real trackThickness:  12
    readonly property bool highlighted: control.interactive && (control.hovered || control.pressed)
    readonly property real handleThickness: control.highlighted ? control.activeThickness
                                                               : control.restThickness

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 0
    hoverEnabled: control.interactive
    visible: control.policy !== T.ScrollBar.AlwaysOff
    minimumSize: orientation === Qt.Horizontal ? height / width : width / height

    /* Children
     * ****************************************************************************************/
    contentItem: Item {
        implicitWidth:  control.trackThickness
        implicitHeight: control.trackThickness
        opacity: 0.0

        Rectangle {
            id: handle

            anchors.centerIn: parent

            width: control.orientation === Qt.Vertical
                   ? Math.min(parent.width, control.handleThickness)
                   : parent.width
            height: control.orientation === Qt.Vertical
                    ? parent.height
                    : Math.min(parent.height, control.handleThickness)
            radius: Math.min(width, height) / 2

            color: {
                if (control.pressed)
                    return Style.colors.scrollBarHandlePressed

                return control.highlighted ? Style.colors.scrollBarHandleHover
                                           : Style.colors.scrollBarHandle
            }

            Behavior on width {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 140
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on color {
                ColorAnimation {
                    duration: 140
                }
            }
        }
    }

    background: Rectangle {
        implicitWidth:  control.trackThickness
        implicitHeight: control.trackThickness
        z: -2
        opacity: 0.0
        visible: control.interactive

        color: control.highlighted ? Style.colors.scrollBarTrackHover
                                   : Style.colors.scrollBarTrack

        Behavior on color {
            ColorAnimation {
                duration: 140
            }
        }
    }

    states: State {
        name: "active"
        when: control.policy === T.ScrollBar.AlwaysOn || (control.active && control.size < 1.0)
    }

    transitions: [
        Transition {
            to: "active"
            NumberAnimation { targets: [control.contentItem, control.background]; property: "opacity"; to: 1.0 }
        },
        Transition {
            from: "active"
            SequentialAnimation {
                PropertyAction{ targets: [control.contentItem, control.background]; property: "opacity"; value: 1.0 }
                PauseAnimation { duration: 2450 }
                NumberAnimation { targets: [control.contentItem, control.background]; property: "opacity"; to: 0.0 }
            }
        }
    ]
}
