import QtQuick

import GitEase_Style

/*! ***********************************************************************************************
 * RepoSectionLabel
 * Small uppercase field label used across the repository dialog tabs.
 * ************************************************************************************************/
Text {
    font.family: Style.fontTypes.inter
    font.pixelSize: 10
    font.weight: Font.DemiBold
    font.letterSpacing: 0.6
    font.capitalization: Font.AllUppercase
    color: Style.colors.mutedText
}
