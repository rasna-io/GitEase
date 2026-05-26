import QtQuick
import QtQuick.Layouts
import QtQuick.Templates as T
import QtQuick.Controls.impl
import QtQuick.Controls.Material
import QtQuick.Controls.Material.impl

import GitEase
import GitEase_Style

/*! ***********************************************************************************************
 * Ronia Button
 * ************************************************************************************************/
T.Button {
    id: control

    property string tooltip:        ""
    property bool   compact:        false
    property real   maximumWidth:   -1

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: Math.max(implicitBackgroundWidth + leftInset + rightInset,
                            implicitContentWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(implicitBackgroundHeight + topInset + bottomInset,
                             implicitContentHeight + topPadding + bottomPadding)

    padding: 6
    spacing: 6
    hoverEnabled: true
    opacity: enabled ? 1.0 : 0.5

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        Row {
            id: row
            anchors.centerIn: parent
            spacing: 5

            Text {
                visible: control.icon.name !== ""
                text: control.icon.name
                font {
                    family: Style.fontTypes.font6ProSolid
                    pixelSize: 13
                }
                color: Style.colors.foreground
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                width: control.maximumWidth > 0 ?
                       Math.min(control.maximumWidth, scrollText.implicitWidth) :
                       scrollText.implicitWidth
                height: scrollText.implicitHeight
                anchors.verticalCenter: parent.verticalCenter

                ScrollingText {
                    id: scrollText
                    anchors.fill: parent
                    text: control.text
                    font{
                        family: Style.fontTypes.roboto
                        pixelSize: 11
                        weight: Font.Medium
                    }
                    color: Style.colors.foreground
                    visible: !control.compact
                }
            }
        }
    }

    background: Rectangle {
        radius: 5
        color: !control.enabled ? Style.colors.primaryBackground :
               control.down ? Style.colors.surfaceMuted :
               control.hovered ? Style.colors.cardBackground : Style.colors.secondaryBackground
    }

    ToolTip {
        visible: control.hovered && control.tooltip !== ""
        text: control.tooltip
        delay: 600
        x: (parent.width - width) / 2
        y: -height - 6
        padding: 6
        background: Rectangle {
            radius: 6
            color: Qt.rgba(0, 0, 0, 0.85)
            border.color: Qt.rgba(1, 1, 1, 0.12)
            border.width: 1
        }
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
