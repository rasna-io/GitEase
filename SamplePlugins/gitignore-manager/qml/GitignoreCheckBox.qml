import QtQuick
import QtQuick.Controls

import GitEase_Style

/*! ***********************************************************************************************
 * GitignoreCheckBox
 * Check box with the look of the app's item selector popup: a 14 px rounded square that fills with
 * the accent colour and shows a white check mark. An optional label sits to its right.
 *
 * Set \a onAccent when the box lies on an accent-coloured row, so it stays visible there.
 * ************************************************************************************************/
AbstractButton {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property bool onAccent: false

    /* Object Properties
     * ****************************************************************************************/
    checkable: true
    hoverEnabled: true
    padding: 0
    spacing: Style.dp(8)

    implicitWidth: Style.dp(24) + (text.length > 0 ? label.implicitWidth + spacing : 0)
    implicitHeight: Style.dp(24)
    opacity: enabled ? 1.0 : 0.45

    font.family: Style.fontTypes.inter
    font.pixelSize: Style.appFont.defaultPt

    indicator: Rectangle {
        x: Style.dp(5)
        y: (root.height - height) / 2
        width: Style.dp(14)
        height: Style.dp(14)
        radius: 4

        color: root.checked ? (root.onAccent ? Style.colors.onAccentText : Style.colors.accent)
                            : Style.colors.primaryBackground
        border.width: 1
        border.color: root.checked ? (root.onAccent ? Style.colors.onAccentText : Style.colors.accent)
                                   : root.hovered ? Style.colors.accent : Style.colors.primaryBorder

        Behavior on color { ColorAnimation { duration: Style.motionFast } }

        Text {
            anchors.centerIn: parent
            visible: root.checked
            text: Style.icons.check
            font.family: Style.fontTypes.font6Pro
            font.styleName: "Solid"
            font.pixelSize: Style.appFont.captionPt
            color: root.onAccent ? Style.colors.accent : "white"
        }
    }

    contentItem: Text {
        id: label
        leftPadding: Style.dp(24)
        text: root.text
        visible: root.text.length > 0
        verticalAlignment: Text.AlignVCenter
        font: root.font
        color: Style.colors.foreground
        elide: Text.ElideRight
    }

    HoverHandler { cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor }
}
