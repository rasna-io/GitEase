import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * SectionLabel
 * Small uppercase caption used to head the groups in the conflict window.
 * ************************************************************************************************/
Text {
    color: Style.colors.conflictSectionLabel
    font.family: Style.fontTypes.inter
    font.weight: Font.DemiBold
    font.letterSpacing: 1.2
    font.pixelSize: Style.appFont.microPt
    leftPadding: 12
    topPadding: 8
    bottomPadding: 4
}
