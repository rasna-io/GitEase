import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * PopupButton
 * Footer button of a PopupDialog. Neutral is outlined (Cancel); Primary and Destructive are filled
 * with the accent and error colors. A disabled filled button turns grey, so a form can keep its
 * main action visible until the input is valid.
 * ************************************************************************************************/
Button {
    id: root

    enum Tone {
        Neutral,
        Primary,
        Destructive
    }

    /* Property Declarations
     * ****************************************************************************************/
    property int    tone:    PopupButton.Neutral
    property string tooltip: ""

    readonly property bool  filled:     root.tone !== PopupButton.Neutral

    readonly property color fillColor:  root.tone === PopupButton.Destructive ? Style.colors.error
                                                                              : Style.colors.accent

    readonly property color hoverColor: root.tone === PopupButton.Destructive ? Qt.darker(Style.colors.error, 1.15)
                                                                              : Style.colors.accentHover

    /* Object Properties
     * ****************************************************************************************/
    Layout.alignment: Qt.AlignVCenter
    Layout.preferredWidth: Math.max(root.filled ? 130 : 100,
                                    root.implicitContentWidth + root.leftPadding + root.rightPadding)

    topInset: 0
    bottomInset: 0
    topPadding: 6
    bottomPadding: 6
    leftPadding: 16
    rightPadding: 16
    hoverEnabled: true

    ToolTip.visible: root.hovered && root.tooltip !== ""
    ToolTip.text: root.tooltip
    ToolTip.delay: 400

    /* Children
     * ****************************************************************************************/
    background: Rectangle {
        implicitHeight: 32
        radius: 5
        color: {
            if (!root.filled)
                return "transparent"

            if (!root.enabled)
                return Style.colors.disabledButton

            return root.hovered ? root.hoverColor : root.fillColor
        }
        border.width: root.filled ? 0 : 1
        border.color: Style.colors.popupCancelButtonBorder
        opacity: root.filled || (root.enabled && root.hovered) ? 1.0 : 0.7

        Behavior on color { ColorAnimation { duration: Style.motionFast } }
    }

    contentItem: Text {
        text: root.text
        color: root.filled ? Style.colors.popupCreateButtonText
                           : Style.colors.popupCancelButtonText
        opacity: root.filled || root.enabled ? 1.0 : 0.5
        font.family: Style.fontTypes.inter
        font.weight: Font.Medium
        font.pixelSize: Style.appFont.defaultPt
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }
}
