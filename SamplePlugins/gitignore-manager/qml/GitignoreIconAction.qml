import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * GitignoreIconAction
 * A bare icon that turns \a hoverColor under the pointer and shows a tooltip. It has no
 * background of its own, so it never fights with the hover colour of the row it sits in.
 * ************************************************************************************************/
Text {
    id: root

    /* Property Declarations
     * ****************************************************************************************/
    property string tooltip:    ""
    property color  hoverColor: Style.colors.accent

    /* Signals
     * ****************************************************************************************/
    signal clicked()

    /* Object Properties
     * ****************************************************************************************/
    font.family: Style.fontTypes.font6Pro
    font.pixelSize: Style.appFont.captionPt
    color: actionHover.hovered ? hoverColor : Style.colors.secondaryText

    Behavior on color { ColorAnimation { duration: Style.motionFast } }

    /* Children
     * ****************************************************************************************/
    HoverHandler {
        id: actionHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler { onTapped: root.clicked() }

    GitignoreToolTip {
        visible: actionHover.hovered && root.tooltip.length > 0
        text: root.tooltip
    }
}
