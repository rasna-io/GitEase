import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * ReleaseLabel
 * Small upper-case caption above a group of controls.
 * ************************************************************************************************/
Text {
    font.family: Style.fontTypes.inter
    font.pixelSize: Style.appFont.microPt
    font.weight: Font.DemiBold
    font.letterSpacing: 0.8
    color: Style.colors.pluginSectionLabel
    elide: Text.ElideRight
}
