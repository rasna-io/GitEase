import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * GitignoreTextLink
 * Small accent-coloured text that acts as a button.
 * ************************************************************************************************/
Text {
    id: root

    signal clicked()

    font.family: Style.fontTypes.inter
    font.pixelSize: Style.appFont.microPt
    font.weight: Font.Medium
    font.underline: linkHover.hovered
    color: enabled ? Style.colors.accent : Style.colors.mutedText

    HoverHandler {
        id: linkHover
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
    }

    TapHandler {
        enabled: root.enabled
        onTapped: root.clicked()
    }
}
