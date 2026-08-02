import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * ConflictPillButton
 * Small outlined button used throughout the conflict window: chunk navigation, per-block resolution
 * actions, and the footer commands.
 * ************************************************************************************************/
Rectangle {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property alias  text:           label.text
    property string leadingText:    ""
    property string trailingText:   ""
    property color  accentColor:    Style.colors.accent
    //! Fills the button with accentColor instead of only outlining it.
    property bool   prominent:      false
    property string tooltip:        ""

    property bool   actionEnabled:  true

    readonly property color _accentWash: Qt.rgba(root.accentColor.r, root.accentColor.g,
                                                 root.accentColor.b, 0.18)
    readonly property color _accentEdge: Qt.rgba(root.accentColor.r, root.accentColor.g,
                                                 root.accentColor.b, 0.55)
    readonly property bool _highlighted: root.actionEnabled && hoverHandler.hovered

    /* Signals
     * ****************************************************************************************/
    signal clicked()

    /* Object Properties
     * ****************************************************************************************/
    implicitWidth: contentRow.implicitWidth + 20
    implicitHeight: Style.dp(24)
    radius: 4

    opacity: root.actionEnabled ? 1.0 : 0.45
    color: {
        if (root.prominent)
            return root._highlighted ? Qt.lighter(root.accentColor, 1.15) : root.accentColor

        return root._highlighted ? root._accentWash : "transparent"
    }

    border.width: 1
    border.color: root.prominent ? root.accentColor : root._accentEdge

    Behavior on color { ColorAnimation { duration: 120 } }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: hoverHandler
        cursorShape: root.actionEnabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor
    }

    TapHandler {
        enabled: root.actionEnabled
        gesturePolicy: TapHandler.ReleaseWithinBounds
        onTapped: root.clicked()
    }

    ToolTip {
        visible: root.tooltip !== "" && hoverHandler.hovered
        text: root.tooltip
        delay: 400
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: 5

        Text {
            visible: root.leadingText !== ""
            text: root.leadingText
            color: root.prominent ? Style.colors.onAccentText : root.accentColor
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
        }

        Text {
            id: label
            color: root.prominent ? Style.colors.onAccentText : root.accentColor
            font.family: Style.fontTypes.inter
            font.weight: Font.Medium
            font.pixelSize: Style.appFont.captionPt
        }

        Text {
            visible: root.trailingText !== ""
            text: root.trailingText
            color: root.prominent ? Style.colors.onAccentText : root.accentColor
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.captionPt
        }
    }
}
