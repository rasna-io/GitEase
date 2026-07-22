import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * SpinboxItem
 * ************************************************************************************************/
ColumnLayout {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string title:       ""
    property string description: ""
    property alias  from:        spinBox.from
    property alias  to:          spinBox.to
    property alias  value:       spinBox.value

    spacing: 8

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Text {
            Layout.fillWidth: true
            text: root.title
            font.family: Style.fontTypes.inter
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: Style.colors.foreground
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            font.family: Style.fontTypes.inter
            font.pixelSize: 10
            color: Style.colors.mutedText
        }
    }

    SpinBox {
        id: spinBox
        Layout.fillWidth: true
        from: 1
        to: 10
        value: 5
        editable: false
        font.family: Style.fontTypes.inter

        contentItem: Text {
            text: spinBox.displayText
            font.family: Style.fontTypes.inter
            font.pixelSize: 12
            color: Style.colors.foreground
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            implicitWidth: 112
            implicitHeight: 30
            radius: 6
            color: Style.colors.controlBackground
            border.width: 1
            border.color: spinBox.hovered ? Style.colors.controlBorderHover
                                          : Style.colors.controlBorder

            Behavior on border.color {
                ColorAnimation {
                    duration: 150
                }
            }
        }

        down.indicator: Rectangle {
            x: spinBox.spacing
            y: (spinBox.height - height) / 2
            implicitWidth: 26
            implicitHeight: 24
            radius: 5
            color: spinBox.down.pressed ? Style.colors.accent
                   : spinBox.down.hovered ? Style.colors.controlBackgroundHover
                                          : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Text {
                anchors.centerIn: parent
                text: Style.icons.minus
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: 11
                color: spinBox.down.pressed ? Style.colors.onAccentText
                                            : Style.colors.foreground
                opacity: spinBox.down.indicator.enabled ? 1 : 0.35
            }
        }

        up.indicator: Rectangle {
            x: spinBox.width - width - spinBox.spacing
            y: (spinBox.height - height) / 2
            implicitWidth: 26
            implicitHeight: 24
            radius: 5
            color: spinBox.up.pressed ? Style.colors.accent
                   : spinBox.up.hovered ? Style.colors.controlBackgroundHover
                                        : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Text {
                anchors.centerIn: parent
                text: Style.icons.plus
                font.family: Style.fontTypes.font6ProSolid
                font.pixelSize: 11
                color: spinBox.up.pressed ? Style.colors.onAccentText
                                          : Style.colors.foreground
                opacity: spinBox.up.indicator.enabled ? 1 : 0.35
            }
        }
    }
}

