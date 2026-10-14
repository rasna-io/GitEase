import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * GitignoreSearchField
 * The app's TextField with the compact look used across the page.
 * ************************************************************************************************/
TextField {
    minHeight: Style.dp(32)
    baseFontSize: Style.appFont.captionPt
    icon: Style.icons.search
    iconSize: Style.appFont.captionPt
    backgroundColor: Style.colors.controlBackground
    borderColor: Style.colors.controlBorder
}
