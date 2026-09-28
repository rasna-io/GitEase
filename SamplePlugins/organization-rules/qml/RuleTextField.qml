import QtQuick
import QtQuick.Controls

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RuleTextField
 * Single-line input styled like the GitEase settings / popup form controls.
 * ************************************************************************************************/
TextField {
    id: root

    /* Object Properties
     * ****************************************************************************************/
    selectByMouse: true
    minHeight: 34
    baseFontSize: Style.appFont.defaultPt
    borderRadius: 7
    focusBorderWidth: 1
    backgroundColor: hovered && !activeFocus ? Style.colors.controlBackgroundHover
                                             : Style.colors.controlBackground
    borderColor: hovered ? Style.colors.controlBorderHover : Style.colors.controlBorder
    focusBorderColor: Style.colors.accent
    iconSize: Style.appFont.defaultPt
    iconColor: Style.colors.placeholderText
}
