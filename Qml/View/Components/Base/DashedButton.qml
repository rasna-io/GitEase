import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * DashedButton
 * ************************************************************************************************/
AbstractButton {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property real   radius:          Style.dp(4)
    property string iconText:        Style.icons.plus
    property real   disabledOpacity: 0.4
    property color  textColor:       root.hovered && root.enabled ? Style.colors.dashedButtonTextHover
                                                                  : Style.colors.dashedButtonText
    property color  borderColor:     root.hovered && root.enabled ? Style.colors.dashedButtonBorderHover
                                                                  : Style.colors.dashedButtonBorder


    readonly property color effectiveTextColor:
        root.enabled ? root.textColor
                     : Qt.rgba(root.textColor.r, root.textColor.g, root.textColor.b,
                               root.disabledOpacity)

    readonly property color effectiveBorderColor:
        root.enabled ? root.borderColor
                     : Qt.rgba(root.borderColor.r, root.borderColor.g, root.borderColor.b,
                               root.disabledOpacity)

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: Style.dp(27)
    implicitWidth:  label.implicitWidth + Style.dp(28)

    hoverEnabled: true

    font.family:    Style.fontTypes.inter
    font.weight:    Font.Medium
    font.pixelSize: Style.appFont.captionPt

    onEffectiveBorderColorChanged: dashedBorder.requestPaint()

    /* Children
     * ****************************************************************************************/
    background: Item {
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.hovered && root.enabled ? Style.colors.dashedButtonBackgroundHover
                                                : "transparent"

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }
        }

        Canvas {
            id: dashedBorder
            anchors.fill: parent
            antialiasing: true

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()

                const inset = 0.5
                const w = width  - inset * 2
                const h = height - inset * 2
                if (w <= 0 || h <= 0)
                    return

                const r = Math.min(root.radius, w / 2, h / 2)

                ctx.strokeStyle = root.effectiveBorderColor
                ctx.lineWidth = 1
                ctx.setLineDash([2, 2])

                ctx.beginPath()
                ctx.moveTo(inset + r, inset)
                ctx.lineTo(inset + w - r, inset)
                ctx.arcTo(inset + w, inset, inset + w, inset + r, r)
                ctx.lineTo(inset + w, inset + h - r)
                ctx.arcTo(inset + w, inset + h, inset + w - r, inset + h, r)
                ctx.lineTo(inset + r, inset + h)
                ctx.arcTo(inset, inset + h, inset, inset + h - r, r)
                ctx.lineTo(inset, inset + r)
                ctx.arcTo(inset, inset, inset + r, inset, r)
                ctx.closePath()
                ctx.stroke()
            }
        }
    }

    contentItem: Item {
        Row {
            anchors.centerIn: parent
            spacing: Style.dp(6)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.iconText.length > 0
                text: root.iconText
                font.family: Style.fontTypes.font6Pro
                font.weight: 400
                font.pixelSize: root.font.pixelSize
                color: root.effectiveTextColor
            }

            Text {
                id: label
                anchors.verticalCenter: parent.verticalCenter
                text: root.text
                font: root.font
                color: root.effectiveTextColor
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.NoButton
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }
}
