import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * RuleButton
 * Compact action button matching the GitEase plugin surfaces.
 * variant: "primary" | "secondary" | "danger"
 * ************************************************************************************************/
Button {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string variant: "secondary"
    property string iconText: ""

    readonly property bool isPrimary: variant === "primary"
    readonly property bool isDanger: variant === "danger"

    readonly property color foregroundColor: isPrimary ? Style.colors.onAccentText
                                           : isDanger  ? Style.colors.error
                                                       : (hovered ? Style.colors.foreground
                                                                  : Style.colors.pluginBtnSecondaryText)

    /* Object Properties
     * ****************************************************************************************/
    implicitHeight: 32
    implicitWidth: contentRow.implicitWidth + leftPadding + rightPadding
    topInset: 0
    bottomInset: 0
    leftPadding: 14
    rightPadding: 14
    hoverEnabled: true
    opacity: enabled ? 1.0 : 0.45

    Behavior on opacity { NumberAnimation { duration: Style.motionFast } }

    background: Rectangle {
        radius: 7
        color: root.isPrimary ? (root.hovered ? Style.colors.accentHover : Style.colors.accent)
             : root.isDanger  ? (root.hovered ? Style.colors.stashActionDangerHoverBackground : "transparent")
                              : (root.hovered ? Style.colors.controlBackgroundHover : Style.colors.pluginCardBackground)
        border.width: root.isPrimary ? 0 : 1
        border.color: root.isDanger ? Style.colors.error
                    : root.hovered  ? Style.colors.controlBorderHover
                                    : Style.colors.pluginBtnSecondaryBorder

        Behavior on color { ColorAnimation { duration: Style.motionFast; easing.type: Easing.OutCubic } }
        Behavior on border.color { ColorAnimation { duration: Style.motionFast; easing.type: Easing.OutCubic } }
    }

    contentItem: Item {
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight

        Row {
            id: contentRow
            anchors.centerIn: parent
            spacing: 7

            Text {
                visible: root.iconText !== ""
                anchors.verticalCenter: parent.verticalCenter
                text: root.iconText
                font.family: Style.fontTypes.font6Pro
                font.styleName: "Solid"
                font.pixelSize: Style.appFont.captionPt
                color: root.foregroundColor
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: root.text
                font.family: Style.fontTypes.inter
                font.pixelSize: Style.appFont.defaultPt
                font.weight: Font.Medium
                color: root.foregroundColor
            }
        }
    }

    HoverHandler { cursorShape: Qt.PointingHandCursor }
}
