import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import GitEase_Style
import GitEase_Style_Impl

/*! ***********************************************************************************************
 * RepoTextField
 * ************************************************************************************************/
TextField {
    Layout.fillWidth: true
    minHeight: 30
    borderRadius: 6
    baseFontSize: 12
    backgroundColor: Style.colors.controlBackground
    borderColor: Style.colors.controlBorder
    focusBorderColor: Style.colors.accent
    iconColor: Style.colors.mutedText
    placeholderTextColor: Style.colors.placeholderText
}
