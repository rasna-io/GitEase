import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs

import GitEase_Style
import GitEase_Style_Impl
import GitEase

/*! ***********************************************************************************************
 * TextFieldItem
 * ************************************************************************************************/
RowLayout {
    id: root

    /* Property Declarations
    * ****************************************************************************************/
    property    string title:            ""
    property    string description:      ""
    property    alias  text:             txf.text
    property    alias  validator:        txf.validator
    property    alias  inputMethodHints: txf.inputMethodHints
    property    alias  echoMode:         txf.echoMode
    property    alias  placeholderText:  txf.placeholderText
    property    alias  field:            txf

    /* Children
     * ****************************************************************************************/
    ColumnLayout {
        Layout.fillWidth: true

        Text {
            Layout.fillWidth: true
            text: root.title
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.mediumPt
            font.weight: Font.DemiBold
            color: Style.colors.foreground
        }

        Text {
            Layout.fillWidth: true
            text: root.description
            font.family: Style.fontTypes.inter
            font.pixelSize: Style.appFont.smallPt
            color: Style.colors.mutedText
        }
    }

    TextField {
        id: txf
        Layout.preferredWidth: 280
        Layout.minimumWidth: 160
        minHeight: 30
        borderRadius: 6
        baseFontSize: 12
        backgroundColor: Style.colors.controlBackground
        borderColor: Style.colors.controlBorder
        focusBorderColor: Style.colors.accent
    }
}
